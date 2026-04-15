# @oagen-ignore-file
require "test_helper"
require "openssl"

class WebhookVerifyTest < Minitest::Test
  SECRET = "whsec_test_secret"

  def setup
    @client = WorkOS::Client.new(api_key: "sk_test_webhook")
    @webhooks = @client.webhooks
  end

  def signed(payload, ts: now_ms, secret: SECRET)
    sig = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{ts}.#{payload}")
    "t=#{ts}, v1=#{sig}"
  end

  def now_ms
    (Time.now.to_f * 1000).to_i
  end

  def test_verify_methods_exist
    assert_respond_to @webhooks, :verify_event
    assert_respond_to @webhooks, :verify_header
    assert_respond_to @webhooks, :compute_signature
    assert_respond_to @webhooks, :parse_signature_header
  end

  def test_verify_event_returns_parsed_payload
    payload = '{"id":"evt_1","event":"user.created"}'
    sig_header = signed(payload)
    event = @webhooks.verify_event(payload: payload, sig_header: sig_header, secret: SECRET)
    assert_equal "evt_1", event["id"]
    assert_equal "user.created", event["event"]
  end

  def test_verify_header_passes_for_valid_signature
    payload = '{"x":1}'
    assert @webhooks.verify_header(payload: payload, sig_header: signed(payload), secret: SECRET)
  end

  def test_verify_header_raises_on_bad_signature
    payload = '{"x":1}'
    bad = "t=#{now_ms}, v1=deadbeef"
    assert_raises(WorkOS::SignatureVerificationError) do
      @webhooks.verify_header(payload: payload, sig_header: bad, secret: SECRET)
    end
  end

  def test_verify_header_raises_on_stale_timestamp
    payload = '{"x":1}'
    old_ts = now_ms - (10 * 60 * 1000) # 10 minutes old
    sig = OpenSSL::HMAC.hexdigest("SHA256", SECRET, "#{old_ts}.#{payload}")
    header = "t=#{old_ts}, v1=#{sig}"
    err = assert_raises(WorkOS::SignatureVerificationError) do
      @webhooks.verify_header(payload: payload, sig_header: header, secret: SECRET, tolerance: 60)
    end
    assert_match(/Timestamp outside the tolerance zone/, err.message)
  end

  def test_verify_header_raises_on_malformed_header
    assert_raises(WorkOS::SignatureVerificationError) do
      @webhooks.verify_header(payload: "{}", sig_header: "garbage", secret: SECRET)
    end
    assert_raises(WorkOS::SignatureVerificationError) do
      @webhooks.verify_header(payload: "{}", sig_header: nil, secret: SECRET)
    end
  end

  def test_compute_signature_matches_manual_hmac
    payload = "hello"
    ts = "1700000000000"
    expected = OpenSSL::HMAC.hexdigest("SHA256", SECRET, "#{ts}.#{payload}")
    assert_equal expected, @webhooks.compute_signature(payload: payload, timestamp: ts, secret: SECRET)
  end

  def test_parse_signature_header
    ts, sig = @webhooks.parse_signature_header("t=12345, v1=abcdef")
    assert_equal "12345", ts
    assert_equal "abcdef", sig
  end
end
