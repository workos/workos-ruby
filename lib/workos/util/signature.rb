# frozen_string_literal: true

# @oagen-ignore-file
require "openssl"

module WorkOS
  module Util
    module Signature
      module_function

      # Computes the expected signature hash for a webhook or action payload.
      #
      # @param payload [String] Raw request body.
      # @param timestamp [String] Timestamp extracted from the signature header.
      # @param secret [String] Webhook or action signing secret.
      # @return [String]
      def compute(payload:, timestamp:, secret:)
        OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{payload}")
      end

      # Parses the WorkOS signature header.
      #
      # @param sig_header [String] Header value in `t=..., v1=...` format.
      # @return [Array(String, String)]
      # @raise [ArgumentError] If the header is missing or malformed.
      def parse_header(sig_header)
        raise ArgumentError, "Signature header missing" if sig_header.nil? || sig_header.empty?

        parts = sig_header.split(",").map(&:strip)
        timestamp = parts.find { |part| part.start_with?("t=") }&.sub(/\At=/, "")
        signature = parts.find { |part| part.start_with?("v1=") }&.sub(/\Av1=/, "")
        raise ArgumentError, "Unable to extract timestamp and signature hash from header" if timestamp.nil? || signature.nil?

        [timestamp, signature]
      end

      # Compares two signature hashes in constant time.
      #
      # @param a [String]
      # @param b [String]
      # @return [Boolean]
      def secure_compare(a, b)
        return false if a.bytesize != b.bytesize

        OpenSSL.fixed_length_secure_compare(a, b)
      rescue NoMethodError
        left = a.unpack("C*")
        result = 0
        index = -1
        b.each_byte { |byte| result |= byte ^ left[index += 1] }
        result.zero?
      end
    end
  end
end
