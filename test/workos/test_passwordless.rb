# frozen_string_literal: true

# @oagen-ignore-file
require "test_helper"

class PasswordlessTest < Minitest::Test
  def setup
    @client = WorkOS::Client.new(api_key: "sk_test_passwordless")
  end

  def test_passwordless_accessor_exists
    assert_kind_of WorkOS::Passwordless, @client.passwordless
  end

  def test_create_session_returns_passwordless_session_struct
    payload = {
      id: "passwordless_session_01",
      email: "user@example.com",
      expires_at: "2026-04-15T12:00:00Z",
      link: "https://workos.com/magic/abc",
      object: "passwordless_session"
    }
    stub_request(:post, "https://api.workos.com/passwordless/sessions")
      .with(body: hash_including("email" => "user@example.com", "type" => "MagicLink"))
      .to_return(status: 200, body: payload.to_json)

    result = @client.passwordless.create_session(email: "user@example.com")
    assert_equal "passwordless_session_01", result.id
    assert_equal "user@example.com", result.email
    assert_equal "https://workos.com/magic/abc", result.link
    assert_equal "passwordless_session", result.object
  end

  def test_create_session_forwards_optional_params
    stub_request(:post, "https://api.workos.com/passwordless/sessions")
      .with(body: hash_including(
        "email" => "user@example.com",
        "redirect_uri" => "https://app.example.com/cb",
        "state" => "xyz",
        "connection" => "conn_123"
      ))
      .to_return(status: 200, body: '{"id":"s","email":"user@example.com","expires_at":"x","link":"y"}')

    @client.passwordless.create_session(
      email: "user@example.com",
      redirect_uri: "https://app.example.com/cb",
      state: "xyz",
      connection: "conn_123"
    )
  end

  def test_send_session_posts_to_send_endpoint
    stub_request(:post, "https://api.workos.com/passwordless/sessions/sess_42/send")
      .to_return(status: 200, body: '{"success":true}')

    result = @client.passwordless.send_session("sess_42")
    assert_equal({"success" => true}, result)
  end
end
