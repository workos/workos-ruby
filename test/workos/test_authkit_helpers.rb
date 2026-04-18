# frozen_string_literal: true

# @oagen-ignore-file
require "test_helper"
require "uri"

class AuthKitHelpersTest < Minitest::Test
  def setup
    @client = WorkOS::Client.new(api_key: "sk_test_authkit", client_id: "client_001")
    @um = @client.user_management
  end

  # H09
  def test_get_authorization_url_returns_string_no_http
    url = @um.get_authorization_url(
      redirect_uri: "https://app.example.com/cb",
      provider: "GoogleOAuth"
    )
    assert_kind_of String, url
    parsed = URI.parse(url)
    params = URI.decode_www_form(parsed.query).to_h
    assert_equal "client_001", params["client_id"]
    assert_equal "https://app.example.com/cb", params["redirect_uri"]
    assert_equal "code", params["response_type"]
    assert_equal "GoogleOAuth", params["provider"]
    assert_equal "/user_management/authorize", parsed.path
  end

  def test_get_authorization_url_requires_client_id
    client = WorkOS::Client.new(api_key: "k", client_id: nil)
    err = assert_raises(ArgumentError) do
      client.user_management.get_authorization_url(redirect_uri: "x", provider: "GoogleOAuth")
    end
    assert_match(/client_id is required/, err.message)
  end

  def test_get_authorization_url_requires_provider_or_connection_or_org
    err = assert_raises(ArgumentError) do
      @um.get_authorization_url(redirect_uri: "x")
    end
    assert_match(/provider, connection_id, or organization_id required/, err.message)
  end

  # H10
  def test_get_authorization_url_with_pkce_returns_url_verifier_state
    url, verifier, state = @um.get_authorization_url_with_pkce(
      redirect_uri: "https://app.example.com/cb",
      provider: "GoogleOAuth"
    )
    assert_kind_of String, url
    assert_kind_of String, verifier
    assert_kind_of String, state
    parsed = URI.parse(url)
    params = URI.decode_www_form(parsed.query).to_h
    assert_equal "S256", params["code_challenge_method"]
    expected_challenge = WorkOS::PKCE.generate_code_challenge(verifier)
    assert_equal expected_challenge, params["code_challenge"]
  end

  # H11
  def test_authenticate_with_code_pkce_posts_correct_body
    stub = stub_request(:post, "https://api.workos.com/user_management/authenticate")
      .with(body: hash_including(
        "grant_type" => "authorization_code",
        "client_id" => "client_001",
        "code" => "auth_code_xyz",
        "code_verifier" => "verifier_abc"
      ))
      .to_return(status: 200, body: '{"user":{"id":"u_1","email":"a@b","first_name":null,"last_name":null,"email_verified":true,"profile_picture_url":null,"created_at":"x","updated_at":"y","object":"user","external_id":null,"last_sign_in_at":null}}')
    @um.authenticate_with_code_pkce(code: "auth_code_xyz", code_verifier: "verifier_abc")
    assert_requested(stub)
  end

  # H12
  def test_authorize_device_initiates_device_flow
    stub = stub_request(:post, "https://api.workos.com/oauth2/device_authorization")
      .with(body: hash_including("client_id" => "client_001"))
      .to_return(status: 200, body: '{"device_code":"d_1","user_code":"ABCD","verification_uri":"u","verification_uri_complete":"uc","expires_in":600,"interval":5}')
    resp = @um.authorize_device
    refute_nil resp
    assert_requested(stub)
  end

  # H13
  def test_get_jwks_url_builds_string
    url = @um.get_jwks_url
    assert_equal "https://api.workos.com/sso/jwks/client_001", url
  end

  def test_get_jwks_url_accepts_explicit_client_id
    assert_equal "https://api.workos.com/sso/jwks/abc", @um.get_jwks_url(client_id: "abc")
  end

  # get_logout_url
  def test_get_logout_url_builds_url
    url = @um.get_logout_url(session_id: "session_01H93ZY4F80QPBEZ1R5B2SHQG8")
    parsed = URI.parse(url)
    params = URI.decode_www_form(parsed.query).to_h
    assert_equal "/user_management/sessions/logout", parsed.path
    assert_equal "session_01H93ZY4F80QPBEZ1R5B2SHQG8", params["session_id"]
  end

  def test_get_logout_url_includes_return_to
    url = @um.get_logout_url(session_id: "sid_1", return_to: "https://example.com")
    parsed = URI.parse(url)
    params = URI.decode_www_form(parsed.query).to_h
    assert_equal "https://example.com", params["return_to"]
  end
end
