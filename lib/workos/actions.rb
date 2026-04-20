# frozen_string_literal: true

# @oagen-ignore-file
# Hand-maintained AuthKit Actions helpers (H03):
# - request signature verification (incoming)
# - response signing (outgoing Allow/Deny verdict)
# These are client-side cryptographic helpers and never spec-driven.

require "json"
require "openssl"
require "workos/util/signature"

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
  module Actions
    DEFAULT_TOLERANCE_SECONDS = 30

    ACTION_TYPE_TO_RESPONSE_OBJECT = {
      "authentication" => "authentication_action_response",
      "user_registration" => "user_registration_action_response"
    }.freeze

    module_function

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
      WorkOS::Util::Signature.compute(payload: payload, timestamp: timestamp, secret: secret)
    end

    # Parse a "t=<ms>, v1=<sig>" header into [timestamp, signature].
    def parse_signature_header(sig_header)
      WorkOS::Util::Signature.parse_header(sig_header)
    rescue ArgumentError => e
      raise WorkOS::SignatureVerificationError.new(message: e.message, http_status: nil)
    end

    def secure_compare(a, b)
      WorkOS::Util::Signature.secure_compare(a, b)
    end
  end
end
