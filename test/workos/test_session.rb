# frozen_string_literal: true

require "test_helper"
require "openssl"
require "jwt"

class TestSession < WorkOS::TestCase
  # Simple mock object that responds to methods based on keyword args.
  # Replacement for OpenStruct which is not in Ruby 4 default gems.
  class MockObj
    def initialize(**kwargs)
      @attrs = kwargs
      kwargs.each do |key, value|
        define_singleton_method(key) { value }
      end
    end
  end

  def setup
    super
    WorkOS::Cache.clear
    @client_id = "test_client_id"
    @cookie_password = "test_very_long_cookie_password__"
    @session_data = "test_session_data"
    @jwk = JWT::JWK.new(OpenSSL::PKey::RSA.new(2048), {kid: "sso_oidc_key_pair_123", use: "sig", alg: "RS256"})
    @jwks_hash = {keys: [@jwk.export]}.to_json
    @jwks_url = "https://api.workos.com/sso/jwks/client_123"
    @user_management = Minitest::Mock.new
  end

  # Helper to build a session with the mock user_management and Net::HTTP stubbed
  def build_session(session_data: @session_data, cookie_password: @cookie_password, encryptor: nil)
    args = {
      user_management: @user_management,
      client_id: @client_id,
      session_data: session_data,
      cookie_password: cookie_password
    }
    args[:encryptor] = encryptor if encryptor
    WorkOS::Session.new(**args)
  end

  def with_mocked_jwks
    @user_management.expect(:get_jwks_url, @jwks_url, [@client_id])
    Net::HTTP.stub(:get, @jwks_hash) do
      yield
    end
  end

  # --- initialize ---

  def test_jwks_caching
    WorkOS::Cache.clear

    # First session fetches from remote
    @user_management.expect(:get_jwks_url, @jwks_url, [@client_id])
    session1 = nil
    session2 = nil

    Net::HTTP.stub(:get, @jwks_hash) do
      session1 = build_session

      # Second session should use cache (no additional Net::HTTP.get call needed)
      @user_management.expect(:get_jwks_url, @jwks_url, [@client_id])
      session2 = build_session
    end

    assert_equal session1.jwks.map(&:export), session2.jwks.map(&:export)
  end

  def test_jwks_fetches_from_remote_when_cache_expired
    WorkOS::Cache.clear

    session1 = nil
    session2 = nil

    @user_management.expect(:get_jwks_url, @jwks_url, [@client_id])
    Net::HTTP.stub(:get, @jwks_hash) do
      session1 = build_session
    end

    # Simulate cache expiration by advancing time
    @user_management.expect(:get_jwks_url, @jwks_url, [@client_id])
    Time.stub(:now, Time.now + 301) do
      Net::HTTP.stub(:get, @jwks_hash) do
        session2 = build_session
      end
    end

    assert_equal session1.jwks.map(&:export), session2.jwks.map(&:export)
  end

  def test_raises_error_if_cookie_password_is_nil
    with_mocked_jwks do
      err = assert_raises(ArgumentError) do
        build_session(cookie_password: nil)
      end
      assert_equal "cookiePassword is required", err.message
    end
  end

  def test_raises_error_if_cookie_password_is_empty
    with_mocked_jwks do
      err = assert_raises(ArgumentError) do
        build_session(cookie_password: "")
      end
      assert_equal "cookiePassword is required", err.message
    end
  end

  def test_initializes_with_valid_parameters
    with_mocked_jwks do
      session = build_session
      assert_equal @user_management.object_id, session.user_management.object_id
      assert_equal @client_id, session.client_id
      assert_equal @session_data, session.session_data
      assert_equal @cookie_password, session.cookie_password
      assert_equal JSON.parse(@jwks_hash, symbolize_names: true)[:keys], session.jwks.map(&:export)
      assert_equal ["RS256"], session.jwks_algorithms
    end
  end

  # --- .authenticate ---

  def make_payload(overrides = {})
    {
      sid: "session_id",
      org_id: "org_id",
      role: "role",
      roles: ["role"],
      permissions: ["read"],
      exp: Time.now.to_i + 3600
    }.merge(overrides)
  end

  def make_session_data(payload = nil, cookie_password: @cookie_password)
    payload ||= make_payload
    valid_access_token = JWT.encode(payload, @jwk.signing_key, @jwk[:alg], {kid: @jwk[:kid]})
    WorkOS::Session.seal_data({
      access_token: valid_access_token,
      user: "user",
      impersonator: "impersonator"
    }, cookie_password)
  end

  def test_authenticate_returns_no_session_cookie_provided_when_nil
    with_mocked_jwks do
      session = build_session(session_data: nil)
      result = session.authenticate
      assert_equal false, result[:authenticated]
      assert_equal "NO_SESSION_COOKIE_PROVIDED", result[:reason]
    end
  end

  def test_authenticate_returns_invalid_session_cookie_when_invalid
    with_mocked_jwks do
      session = build_session(session_data: "invalid_data")
      result = session.authenticate
      assert_equal false, result[:authenticated]
      assert_equal "INVALID_SESSION_COOKIE", result[:reason]
    end
  end

  def test_authenticate_returns_invalid_jwt_when_access_token_invalid
    with_mocked_jwks do
      invalid_session_data = WorkOS::Session.seal_data({access_token: "invalid_token"}, @cookie_password)
      session = build_session(session_data: invalid_session_data)
      result = session.authenticate
      assert_equal false, result[:authenticated]
      assert_equal "INVALID_JWT", result[:reason]
    end
  end

  def test_authenticate_returns_invalid_jwt_when_session_expired
    sealed = make_session_data
    with_mocked_jwks do
      session = build_session(session_data: sealed)

      # Monkey-patch JWT::Decode to skip signature verification
      original_verify = JWT::Decode.instance_method(:verify_signature)
      JWT::Decode.define_method(:verify_signature) { true }
      begin
        Time.stub(:now, Time.at(9_999_999_999)) do
          result = session.authenticate
          assert_equal false, result[:authenticated]
          assert_equal "INVALID_JWT", result[:reason]
        end
      ensure
        JWT::Decode.define_method(:verify_signature, original_verify)
      end
    end
  end

  def test_authenticate_returns_invalid_jwt_with_full_token_data_when_expired_and_include_expired
    sealed = make_session_data
    with_mocked_jwks do
      session = build_session(session_data: sealed)

      original_verify = JWT::Decode.instance_method(:verify_signature)
      JWT::Decode.define_method(:verify_signature) { true }
      begin
        Time.stub(:now, Time.at(9_999_999_999)) do
          result = session.authenticate(include_expired: true)
          assert_equal false, result[:authenticated]
          assert_equal "session_id", result[:session_id]
          assert_equal "org_id", result[:organization_id]
          assert_equal "role", result[:role]
          assert_equal ["role"], result[:roles]
          assert_equal ["read"], result[:permissions]
          assert_nil result[:feature_flags]
          assert_nil result[:entitlements]
          assert_equal "user", result[:user]
          assert_equal "impersonator", result[:impersonator]
          assert_equal "INVALID_JWT", result[:reason]
        end
      ensure
        JWT::Decode.define_method(:verify_signature, original_verify)
      end
    end
  end

  def test_authenticate_successfully_with_valid_session_data
    sealed = make_session_data
    with_mocked_jwks do
      session = build_session(session_data: sealed)

      original_verify = JWT::Decode.instance_method(:verify_signature)
      JWT::Decode.define_method(:verify_signature) { true }
      begin
        result = session.authenticate
        assert_equal true, result[:authenticated]
        assert_equal "session_id", result[:session_id]
        assert_equal "org_id", result[:organization_id]
        assert_equal "role", result[:role]
        assert_equal ["role"], result[:roles]
        assert_equal ["read"], result[:permissions]
        assert_nil result[:feature_flags]
        assert_nil result[:entitlements]
        assert_equal "user", result[:user]
        assert_equal "impersonator", result[:impersonator]
        assert_nil result[:reason]
      ensure
        JWT::Decode.define_method(:verify_signature, original_verify)
      end
    end
  end

  def test_authenticate_merges_custom_claims_from_claim_extractor
    custom_payload = make_payload(custom_claim: "custom_value", another_claim: 123)
    custom_access_token = JWT.encode(custom_payload, @jwk.signing_key, @jwk[:alg], {kid: @jwk[:kid]})
    custom_session_data = WorkOS::Session.seal_data({
      access_token: custom_access_token,
      user: "user",
      impersonator: "impersonator"
    }, @cookie_password)

    with_mocked_jwks do
      session = build_session(session_data: custom_session_data)

      original_verify = JWT::Decode.instance_method(:verify_signature)
      JWT::Decode.define_method(:verify_signature) { true }
      begin
        result = session.authenticate do |jwt|
          {my_custom_claim: jwt["custom_claim"], my_other_claim: jwt["another_claim"]}
        end
        assert_equal true, result[:authenticated]
        assert_equal "custom_value", result[:my_custom_claim]
        assert_equal 123, result[:my_other_claim]
      ensure
        JWT::Decode.define_method(:verify_signature, original_verify)
      end
    end
  end

  def test_authenticate_with_entitlements
    payload = make_payload(entitlements: ["billing"])
    sealed = make_session_data(payload)

    with_mocked_jwks do
      session = build_session(session_data: sealed)

      original_verify = JWT::Decode.instance_method(:verify_signature)
      JWT::Decode.define_method(:verify_signature) { true }
      begin
        result = session.authenticate
        assert_equal true, result[:authenticated]
        assert_equal "session_id", result[:session_id]
        assert_equal "org_id", result[:organization_id]
        assert_equal "role", result[:role]
        assert_equal ["role"], result[:roles]
        assert_equal ["read"], result[:permissions]
        assert_equal ["billing"], result[:entitlements]
        assert_nil result[:feature_flags]
        assert_equal "user", result[:user]
        assert_equal "impersonator", result[:impersonator]
        assert_nil result[:reason]
      ensure
        JWT::Decode.define_method(:verify_signature, original_verify)
      end
    end
  end

  def test_authenticate_with_feature_flags
    payload = make_payload(feature_flags: ["new_feature_enabled"])
    sealed = make_session_data(payload)

    with_mocked_jwks do
      session = build_session(session_data: sealed)

      original_verify = JWT::Decode.instance_method(:verify_signature)
      JWT::Decode.define_method(:verify_signature) { true }
      begin
        result = session.authenticate
        assert_equal true, result[:authenticated]
        assert_equal "session_id", result[:session_id]
        assert_equal "org_id", result[:organization_id]
        assert_equal "role", result[:role]
        assert_equal ["role"], result[:roles]
        assert_equal ["read"], result[:permissions]
        assert_nil result[:entitlements]
        assert_equal ["new_feature_enabled"], result[:feature_flags]
        assert_equal "user", result[:user]
        assert_equal "impersonator", result[:impersonator]
        assert_nil result[:reason]
      ensure
        JWT::Decode.define_method(:verify_signature, original_verify)
      end
    end
  end

  # --- .refresh ---

  def test_refresh_returns_invalid_session_cookie_when_invalid
    with_mocked_jwks do
      session = build_session(session_data: "invalid_data")
      result = session.refresh
      assert_equal false, result[:authenticated]
      assert_equal "INVALID_SESSION_COOKIE", result[:reason]
    end
  end

  def test_refresh_successfully_with_valid_session_data
    refresh_token = "test_refresh_token"
    sealed = WorkOS::Session.seal_data({refresh_token: refresh_token, user: "user"}, @cookie_password)
    auth_response = MockObj.new(sealed_session: "new_sealed_session")

    # Build a custom mock that accepts any kwargs for authenticate_with_refresh_token
    um_mock = Object.new
    um_mock.define_singleton_method(:get_jwks_url) { |_client_id| @jwks_url }
    um_mock.instance_variable_set(:@jwks_url, @jwks_url)
    um_mock.define_singleton_method(:authenticate_with_refresh_token) { |**_kwargs| auth_response }

    Net::HTTP.stub(:get, @jwks_hash) do
      session = WorkOS::Session.new(
        user_management: um_mock,
        client_id: @client_id,
        session_data: sealed,
        cookie_password: @cookie_password
      )
      result = session.refresh
      assert_equal true, result[:authenticated]
      assert_equal "new_sealed_session", result[:sealed_session]
      assert_equal auth_response, result[:session]
      assert_nil result[:reason]
    end
  end

  # --- .get_logout_url ---

  def test_get_logout_url_when_authenticated
    Net::HTTP.stub(:get, @jwks_hash) do
      session = WorkOS::Session.new(
        user_management: WorkOS::UserManagement,
        client_id: @client_id,
        session_data: @session_data,
        cookie_password: @cookie_password
      )

      session.stub(:authenticate, {authenticated: true, session_id: "session_123abc", reason: nil}) do
        assert_equal(
          "https://api.workos.com/user_management/sessions/logout?session_id=session_123abc",
          session.get_logout_url
        )
      end
    end
  end

  def test_get_logout_url_with_return_to
    Net::HTTP.stub(:get, @jwks_hash) do
      session = WorkOS::Session.new(
        user_management: WorkOS::UserManagement,
        client_id: @client_id,
        session_data: @session_data,
        cookie_password: @cookie_password
      )

      session.stub(:authenticate, {authenticated: true, session_id: "session_123abc", reason: nil}) do
        assert_equal(
          "https://api.workos.com/user_management/sessions/logout?session_id=session_123abc&return_to=https%3A%2F%2Fexample.com%2Fsigned-out",
          session.get_logout_url(return_to: "https://example.com/signed-out")
        )
      end
    end
  end

  def test_get_logout_url_raises_error_when_authentication_fails
    Net::HTTP.stub(:get, @jwks_hash) do
      session = WorkOS::Session.new(
        user_management: WorkOS::UserManagement,
        client_id: @client_id,
        session_data: @session_data,
        cookie_password: @cookie_password
      )

      session.stub(:authenticate, {authenticated: false, reason: "Invalid session"}) do
        err = assert_raises(RuntimeError) do
          session.get_logout_url
        end
        assert_equal "Failed to extract session ID for logout URL: Invalid session", err.message
      end
    end
  end

  # --- custom encryptor ---

  def custom_encryptor
    @custom_encryptor ||= Class.new do
      def seal(data, _key)
        "CUSTOM:#{JSON.generate(data)}"
      end

      def unseal(sealed_data, _key)
        json = sealed_data.sub("CUSTOM:", "")
        JSON.parse(json, symbolize_names: true)
      end
    end.new
  end

  def test_custom_encryptor_seal_data
    sealed = WorkOS::Session.seal_data({foo: "bar"}, "key", encryptor: custom_encryptor)
    assert sealed.start_with?("CUSTOM:")
  end

  def test_custom_encryptor_unseal_data
    sealed = 'CUSTOM:{"foo":"bar"}'
    unsealed = WorkOS::Session.unseal_data(sealed, "key", encryptor: custom_encryptor)
    assert_equal({foo: "bar"}, unsealed)
  end

  def test_accepts_custom_encryptor_in_initialize
    with_mocked_jwks do
      session = build_session(encryptor: custom_encryptor)
      assert_equal custom_encryptor, session.encryptor
    end
  end

  def test_defaults_to_aes_gcm_encryptor
    with_mocked_jwks do
      session = build_session
      assert_kind_of WorkOS::Encryptors::AesGcm, session.encryptor
    end
  end

  def test_raises_argument_error_for_invalid_encryptor
    with_mocked_jwks do
      err = assert_raises(ArgumentError) do
        build_session(encryptor: Object.new)
      end
      assert_match(/must respond to/, err.message)
    end
  end
end
