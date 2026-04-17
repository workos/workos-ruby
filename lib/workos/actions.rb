# frozen_string_literal: true

# @oagen-ignore-file
# Hand-maintained AuthKit Actions helpers (H03):
# - request signature verification (incoming)
# - response signing (outgoing Allow/Deny verdict)
# These are client-side cryptographic helpers and never spec-driven.

require "json"
require "openssl"

module WorkOS
  # AuthKit Actions request verification + response signing.
  #
  #   action = client.actions.construct_action(
  #     payload: req.body, sig_header: req.headers["WorkOS-Signature"],
  #     secret: ENV["WORKOS_ACTIONS_SECRET"]
  #   )
  #   resp = client.actions.sign_response(
  #     action_type: "authentication", verdict: "Allow",
  #     secret: ENV["WORKOS_ACTIONS_SECRET"]
  #   )
  class Actions
    DEFAULT_TOLERANCE_SECONDS = 30

    ACTION_TYPE_TO_RESPONSE_OBJECT = {
      "authentication" => "authentication_action_response",
      "user_registration" => "user_registration_action_response"
    }.freeze

    def initialize(client = nil)
      # client is unused but accepted for parity with other service accessors.
      @client = client
    end

    # Verify a request signature; raises on failure.
    def verify_header(payload:, sig_header:, secret:, tolerance: DEFAULT_TOLERANCE_SECONDS)
      timestamp_ms, signature_hash = parse_signature_header(sig_header)
      issued_at = timestamp_ms.to_i / 1000.0
      if (Time.now.to_f - issued_at) > tolerance
        raise WorkOS::SignatureVerificationError.new(
          message: "Timestamp outside the tolerance zone",
          http_status: nil
        )
      end
      expected = compute_signature(payload: payload, timestamp: timestamp_ms, secret: secret)
      unless secure_compare(signature_hash, expected)
        raise WorkOS::SignatureVerificationError.new(
          message: "Signature hash does not match the expected signature hash for payload",
          http_status: nil
        )
      end
      true
    end

    # Verify and deserialize an Actions request payload.
    def construct_action(payload:, sig_header:, secret:, tolerance: DEFAULT_TOLERANCE_SECONDS)
      verify_header(payload: payload, sig_header: sig_header, secret: secret, tolerance: tolerance)
      JSON.parse(payload)
    end

    # Build and sign an Actions response. action_type is "authentication" or
    # "user_registration"; verdict is "Allow" or "Deny".
    def sign_response(action_type:, verdict:, secret:, error_message: nil)
      object_type = ACTION_TYPE_TO_RESPONSE_OBJECT[action_type.to_s]
      raise ArgumentError, "Unknown action_type: #{action_type}" unless object_type
      timestamp_ms = (Time.now.to_f * 1000).to_i
      response_payload = {"timestamp" => timestamp_ms, "verdict" => verdict}
      response_payload["error_message"] = error_message if error_message
      payload_json = JSON.generate(response_payload)
      signed_payload = "#{timestamp_ms}.#{payload_json}"
      {
        "object" => object_type,
        "payload" => response_payload,
        "signature" => OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
      }
    end

    # Compute HMAC-SHA256 hex signature for a (timestamp, payload) pair.
    def compute_signature(payload:, timestamp:, secret:)
      OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{payload}")
    end

    # Parse a "t=<ms>, v1=<sig>" header into [timestamp, signature].
    def parse_signature_header(sig_header)
      raise WorkOS::SignatureVerificationError.new(message: "Signature header missing", http_status: nil) if sig_header.nil? || sig_header.empty?
      parts = sig_header.split(", ")
      raise WorkOS::SignatureVerificationError.new(message: "Unable to extract timestamp and signature hash from header", http_status: nil) if parts.size < 2
      [parts[0].sub(/\At=/, ""), parts[1].sub(/\Av1=/, "")]
    end

    private

    def secure_compare(a, b)
      return false if a.bytesize != b.bytesize
      l = a.unpack("C*")
      r = 0
      i = -1
      b.each_byte { |byte| r |= byte ^ l[i += 1] }
      r.zero?
    end
  end
end
