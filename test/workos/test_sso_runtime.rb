# frozen_string_literal: true

require "test_helper"

class SSORuntimeTest < Minitest::Test
  def setup
    @client = WorkOS::Client.new(api_key: "sk_test_sso", client_id: "client_001")
  end

  def test_get_profile_and_token_posts_code_in_body_only
    stub = stub_request(:post, "https://api.workos.com/sso/token")
      .with(
        query: {},
        body: hash_including(
          "grant_type" => "authorization_code",
          "client_id" => "client_001",
          "client_secret" => "sk_test_sso",
          "code" => "code_123"
        )
      )
      .to_return(status: 200, body: "{}")

    @client.sso.get_profile_and_token(code: "code_123")

    assert_requested(stub)
  end

  def test_get_profile_and_token_uses_request_option_credentials
    stub = stub_request(:post, "https://api.workos.com/sso/token")
      .with(
        body: hash_including(
          "client_id" => "client_override",
          "client_secret" => "sk_override"
        )
      )
      .to_return(status: 200, body: "{}")

    @client.sso.get_profile_and_token(
      code: "code_123",
      request_options: {api_key: "sk_override", client_id: "client_override"}
    )

    assert_requested(stub)
  end
end
