# @oagen-ignore-file
require "test_helper"
require "openssl"
require "json"

class ActionsTest < Minitest::Test
  SECRET = "as_test_actions_secret"

  def setup
    @client = WorkOS::Client.new(api_key: "sk_test")
    @actions = @client.actions
  end

  def signed(payload, ts: now_ms, secret: SECRET)
    sig = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{ts}.#{payload}")
    "t=#{ts}, v1=#{sig}"
  end

  def now_ms
    (Time.now.to_f * 1000).to_i
  end

  def test_actions_accessor_exists
    assert_kind_of WorkOS::Actions, @actions
  end

  def test_construct_action_returns_parsed_payload
    payload = '{"object":"authentication_action_context","user":{"email":"a@b.com"}}'
    action = @actions.construct_action(payload: payload, sig_header: signed(payload), secret: SECRET)
    assert_equal "authentication_action_context", action["object"]
    assert_equal "a@b.com", action["user"]["email"]
  end

  def test_verify_header_raises_on_bad_signature
    payload = '{"x":1}'
    assert_raises(WorkOS::SignatureVerificationError) do
      @actions.verify_header(payload: payload, sig_header: "t=#{now_ms}, v1=cafef00d", secret: SECRET)
    end
  end

  def test_verify_header_uses_30s_default_tolerance
    payload = '{"x":1}'
    old_ts = now_ms - 60_000
    sig = OpenSSL::HMAC.hexdigest("SHA256", SECRET, "#{old_ts}.#{payload}")
    assert_raises(WorkOS::SignatureVerificationError) do
      @actions.verify_header(payload: payload, sig_header: "t=#{old_ts}, v1=#{sig}", secret: SECRET)
    end
  end

  def test_sign_response_authentication_allow
    resp = @actions.sign_response(action_type: "authentication", verdict: "Allow", secret: SECRET)
    assert_equal "authentication_action_response", resp["object"]
    assert_equal "Allow", resp["payload"]["verdict"]
    refute_nil resp["payload"]["timestamp"]
    refute_nil resp["signature"]
    payload_json = JSON.generate(resp["payload"])
    expected = OpenSSL::HMAC.hexdigest("SHA256", SECRET, "#{resp["payload"]["timestamp"]}.#{payload_json}")
    assert_equal expected, resp["signature"]
  end

  def test_sign_response_user_registration_deny_with_error
    resp = @actions.sign_response(
      action_type: "user_registration", verdict: "Deny",
      error_message: "blocked", secret: SECRET
    )
    assert_equal "user_registration_action_response", resp["object"]
    assert_equal "Deny", resp["payload"]["verdict"]
    assert_equal "blocked", resp["payload"]["error_message"]
  end

  def test_sign_response_rejects_unknown_action_type
    assert_raises(ArgumentError) do
      @actions.sign_response(action_type: "bogus", verdict: "Allow", secret: SECRET)
    end
  end
end
