# frozen_string_literal: true

# @oagen-ignore-file
require "test_helper"

class PublicClientTest < Minitest::Test
  def test_create_returns_workos_client_with_no_api_key
    client = WorkOS::PublicClient.create(client_id: "client_001")
    assert_kind_of WorkOS::Client, client
    assert_equal "client_001", client.client_id
    assert_nil client.api_key
  end

  def test_create_requires_client_id
    assert_raises(ArgumentError) { WorkOS::PublicClient.create(client_id: nil) }
    assert_raises(ArgumentError) { WorkOS::PublicClient.create(client_id: "") }
  end

  def test_public_client_request_omits_authorization_header
    client = WorkOS::PublicClient.create(client_id: "client_001")
    stub = stub_request(:post, "https://api.workos.com/oauth2/device_authorization")
      .with { |req| !req.headers.key?("Authorization") }
      .to_return(status: 200, body: '{"device_code":"d","user_code":"u","verification_uri":"v","verification_uri_complete":"vc","expires_in":10,"interval":5}')
    client.user_management.authorize_device
    assert_requested(stub)
  end

  def test_public_client_can_build_pkce_authorization_url
    client = WorkOS::PublicClient.create(client_id: "client_001")
    url, verifier, _state = client.user_management.get_authorization_url_with_pkce(
      redirect_uri: "https://app/cb",
      provider: "GoogleOAuth"
    )
    assert_match %r{client_id=client_001}, url
    assert_match %r{code_challenge_method=S256}, url
    assert verifier.length >= 43
  end

  # A public client has no API key to send as `client_secret`. The PKCE
  # helpers never send one. The sign-in methods that do send one for a client
  # with a key get it from BaseClient#client_secret, which gives a public
  # client nil, so the field is left out there too.
  def test_public_client_pkce_flow_sends_no_client_secret_and_no_authorization_header
    client = WorkOS::PublicClient.create(client_id: "client_001")
    requests = []
    %w[/user_management/authenticate /sso/token].each do |path|
      stub_request(:post, "https://api.workos.com#{path}").to_return do |request|
        requests << request
        {status: 200, body: "{}"}
      end
    end

    _url, verifier, _state = client.user_management.get_authorization_url_with_pkce(
      redirect_uri: "https://app/cb",
      provider: "authkit"
    )
    client.user_management.authenticate_with_code_pkce(code: "code_123", code_verifier: verifier)
    client.user_management.authenticate_with_code(code: "code_123", code_verifier: verifier)
    client.sso.get_profile_and_token_with_pkce(code: "code_123", code_verifier: verifier)
    client.sso.get_profile_and_token(code: "code_123", code_verifier: verifier)

    assert_nil client.client_secret("authenticate_with_code")
    assert_equal 4, requests.size
    requests.each do |request|
      body = JSON.parse(request.body)
      refute body.key?("client_secret"), "client_secret was sent to #{request.uri.path}"
      assert_equal "client_001", body["client_id"]
      assert_equal verifier, body["code_verifier"]
      refute(request.headers.keys.any? { |name| name.casecmp?("authorization") }, "an Authorization header was sent to #{request.uri.path}")
    end
  end
end
