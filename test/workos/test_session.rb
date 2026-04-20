# frozen_string_literal: true

# @oagen-ignore-file
require "test_helper"
require "json"
require "openssl"
require "jwt"
require "base64"

class SessionTest < Minitest::Test
  PASSWORD = "very-long-cookie-password-secret"

  def setup
    @client = WorkOS::Client.new(api_key: "sk_test_session", client_id: "client_001")
    @sm = @client.session_manager
  end

  # --- H06 raw seal/unseal round-trip ---------------------------------------

  def test_seal_then_unseal_round_trip_hash
    sealed = @sm.seal_data({"a" => 1, "b" => "two"}, PASSWORD)
    refute_equal "a", sealed
    assert_equal({"a" => 1, "b" => "two"}, @sm.unseal_data(sealed, PASSWORD))
  end

  def test_unseal_with_wrong_key_raises
    sealed = @sm.seal_data({"x" => 1}, PASSWORD)
    assert_raises(OpenSSL::Cipher::CipherError) do
      @sm.unseal_data(sealed, "wrong-password")
    end
  end

  def test_unseal_rejects_short_payload
    assert_raises(ArgumentError) do
      @sm.unseal_data(Base64.strict_encode64("short"), PASSWORD)
    end
  end

  # --- H07 seal_session_from_auth_response ----------------------------------

  def test_seal_session_from_auth_response_is_unsealable
    sealed = @sm.seal_session_from_auth_response(
      access_token: "access_xyz",
      refresh_token: "refresh_xyz",
      cookie_password: PASSWORD,
      user: {"id" => "u_1", "email" => "a@b.com"}
    )
    payload = @sm.unseal_data(sealed, PASSWORD)
    assert_equal "access_xyz", payload["access_token"]
    assert_equal "refresh_xyz", payload["refresh_token"]
    assert_equal "u_1", payload["user"]["id"]
  end

  # --- H04 Session#authenticate with stubbed JWKS ---------------------------

  def signing_key_pair
    rsa = OpenSSL::PKey::RSA.generate(2048)
    [rsa, rsa.public_key]
  end

  def make_jwt(claims, rsa, kid: "test-key")
    JWT.encode(claims, rsa, "RS256", {kid: kid})
  end

  def jwks_payload(public_key, kid: "test-key")
    n = Base64.urlsafe_encode64(public_key.n.to_s(2), padding: false)
    e = Base64.urlsafe_encode64(public_key.e.to_s(2), padding: false)
    {"keys" => [{"kty" => "RSA", "alg" => "RS256", "use" => "sig", "kid" => kid, "n" => n, "e" => e}]}
  end

  def test_authenticate_returns_success_with_decoded_claims
    rsa, pub = signing_key_pair
    access_token = make_jwt({"sid" => "session_42", "org_id" => "org_1", "exp" => Time.now.to_i + 60}, rsa)
    sealed = @sm.seal_data({"access_token" => access_token, "user" => {"id" => "u_1"}}, PASSWORD)

    stub_request(:get, "https://api.workos.com/sso/jwks/client_001")
      .to_return(status: 200, body: jwks_payload(pub).to_json)

    result = @sm.authenticate(seal_data: sealed, cookie_password: PASSWORD)
    assert_kind_of WorkOS::SessionManager::AuthSuccess, result
    assert result.authenticated
    assert_equal "session_42", result.session_id
    assert_equal "org_1", result.organization_id
    assert_equal "u_1", result.user["id"]
  end

  def test_authenticate_merges_custom_claims_from_block
    rsa, pub = signing_key_pair
    access_token = make_jwt(
      {
        "sid" => "session_custom",
        "org_id" => "org_custom",
        "custom_claim" => "custom_value",
        "another_claim" => 123,
        "exp" => Time.now.to_i + 60
      },
      rsa
    )
    sealed = @sm.seal_data({"access_token" => access_token, "user" => {"id" => "u_2"}}, PASSWORD)

    stub_request(:get, "https://api.workos.com/sso/jwks/client_001")
      .to_return(status: 200, body: jwks_payload(pub).to_json)

    result = @sm.authenticate(seal_data: sealed, cookie_password: PASSWORD) do |jwt|
      {
        my_custom_claim: jwt["custom_claim"],
        my_other_claim: jwt["another_claim"]
      }
    end

    assert_kind_of WorkOS::SessionManager::AuthSuccess, result
    assert_equal "custom_value", result[:my_custom_claim]
    assert_equal 123, result[:my_other_claim]
    assert_equal "custom_value", result.my_custom_claim
    assert_equal "custom_value", result.to_h[:my_custom_claim]
  end

  def test_authenticate_rejects_custom_claims_that_overwrite_reserved_keys
    rsa, pub = signing_key_pair
    access_token = make_jwt({"sid" => "session_reserved", "exp" => Time.now.to_i + 60}, rsa)
    sealed = @sm.seal_data({"access_token" => access_token}, PASSWORD)

    stub_request(:get, "https://api.workos.com/sso/jwks/client_001")
      .to_return(status: 200, body: jwks_payload(pub).to_json)

    error = assert_raises(ArgumentError) do
      @sm.authenticate(seal_data: sealed, cookie_password: PASSWORD) do
        {authenticated: false}
      end
    end

    assert_match(/reserved key/, error.message)
  end

  def test_authenticate_returns_no_session_cookie_when_blank
    result = @sm.authenticate(seal_data: "", cookie_password: PASSWORD)
    assert_kind_of WorkOS::SessionManager::AuthError, result
    refute result.authenticated
    assert_equal WorkOS::SessionManager::NO_SESSION_COOKIE_PROVIDED, result.reason
  end

  def test_authenticate_returns_invalid_session_cookie_on_garbage
    result = @sm.authenticate(seal_data: "garbage", cookie_password: PASSWORD)
    assert_equal WorkOS::SessionManager::INVALID_SESSION_COOKIE, result.reason
  end

  def test_authenticate_returns_invalid_jwt_on_bad_signature
    rsa, _pub = signing_key_pair
    other = OpenSSL::PKey::RSA.generate(2048)
    access_token = make_jwt({"sid" => "s", "exp" => Time.now.to_i + 60}, other)
    sealed = @sm.seal_data({"access_token" => access_token}, PASSWORD)

    stub_request(:get, "https://api.workos.com/sso/jwks/client_001")
      .to_return(status: 200, body: jwks_payload(rsa.public_key).to_json)

    result = @sm.authenticate(seal_data: sealed, cookie_password: PASSWORD)
    assert_equal WorkOS::SessionManager::INVALID_JWT, result.reason
  end

  def test_authenticate_returns_expired_jwt_when_expired_and_include_expired_is_false
    rsa, pub = signing_key_pair
    # Token expired 60 seconds ago
    access_token = make_jwt({"sid" => "session_expired", "exp" => Time.now.to_i - 60}, rsa)
    sealed = @sm.seal_data({"access_token" => access_token}, PASSWORD)

    stub_request(:get, "https://api.workos.com/sso/jwks/client_001")
      .to_return(status: 200, body: jwks_payload(pub).to_json)

    result = @sm.authenticate(seal_data: sealed, cookie_password: PASSWORD, include_expired: false)
    assert_equal WorkOS::SessionManager::EXPIRED_JWT, result.reason
    refute result.authenticated
  end

  def test_authenticate_returns_auth_success_with_authenticated_false_when_expired_and_include_expired_is_true
    rsa, pub = signing_key_pair
    # Token expired 60 seconds ago
    access_token = make_jwt({"sid" => "session_expired", "exp" => Time.now.to_i - 60}, rsa)
    sealed = @sm.seal_data({"access_token" => access_token}, PASSWORD)

    stub_request(:get, "https://api.workos.com/sso/jwks/client_001")
      .to_return(status: 200, body: jwks_payload(pub).to_json)

    result = @sm.authenticate(seal_data: sealed, cookie_password: PASSWORD, include_expired: true)
    assert_kind_of WorkOS::SessionManager::AuthSuccess, result
    refute result.authenticated
    assert_equal WorkOS::SessionManager::EXPIRED_JWT, result.reason
    assert_equal "session_expired", result.session_id
  end

  # --- get_logout_url -------------------------------------------------------

  def test_get_logout_url_includes_session_id_from_authenticate
    rsa, pub = signing_key_pair
    access_token = make_jwt({"sid" => "session_logout", "exp" => Time.now.to_i + 60}, rsa)
    sealed = @sm.seal_data({"access_token" => access_token}, PASSWORD)

    stub_request(:get, "https://api.workos.com/sso/jwks/client_001")
      .to_return(status: 200, body: jwks_payload(pub).to_json)

    session = @sm.load(seal_data: sealed, cookie_password: PASSWORD)
    url = session.get_logout_url(return_to: "https://app/cb")
    parsed = URI.parse(url)
    assert_equal "/user_management/sessions/logout", parsed.path
    params = URI.decode_www_form(parsed.query).to_h
    assert_equal "session_logout", params["session_id"]
    assert_equal "https://app/cb", params["return_to"]
  end

  # --- Session constructor validation ---------------------------------------

  def test_session_load_requires_cookie_password
    assert_raises(ArgumentError) { @sm.load(seal_data: "x", cookie_password: nil) }
    assert_raises(ArgumentError) { @sm.load(seal_data: "x", cookie_password: "") }
  end

  # --- BYO encryptor ---------------------------------------------------------

  def test_custom_encryptor_is_used_for_seal_and_unseal
    custom = Object.new
    def custom.seal(data, _key)
      Base64.strict_encode64(JSON.generate(data))
    end

    def custom.unseal(sealed, _key)
      JSON.parse(Base64.decode64(sealed))
    end

    sm = WorkOS::Client.new(api_key: "sk_test_enc", client_id: "client_enc")
      .session_manager(encryptor: custom)

    sealed = sm.seal_data({"a" => 1}, PASSWORD)
    assert_equal({"a" => 1}, JSON.parse(Base64.decode64(sealed)))
    assert_equal({"a" => 1}, sm.unseal_data(sealed, PASSWORD))
  end

  def test_custom_encryptor_authenticate_round_trip
    custom = Object.new

    def custom.seal(data, _key)
      Base64.strict_encode64(data.is_a?(String) ? data : JSON.generate(data))
    end

    def custom.unseal(sealed, _key)
      JSON.parse(Base64.decode64(sealed))
    end

    sm = WorkOS::Client.new(api_key: "sk_test_enc2", client_id: "client_enc2")
      .session_manager(encryptor: custom)

    rsa, pub = signing_key_pair
    access_token = make_jwt({"sid" => "s_custom", "org_id" => "org_c", "exp" => Time.now.to_i + 60}, rsa)
    sealed = sm.seal_data({"access_token" => access_token, "user" => {"id" => "u_c"}}, PASSWORD)

    stub_request(:get, "https://api.workos.com/sso/jwks/client_enc2")
      .to_return(status: 200, body: jwks_payload(pub).to_json)

    result = sm.authenticate(seal_data: sealed, cookie_password: PASSWORD)
    assert_kind_of WorkOS::SessionManager::AuthSuccess, result
    assert_equal "s_custom", result.session_id
  end
end
