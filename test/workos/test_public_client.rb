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
end
