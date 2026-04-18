# frozen_string_literal: true

# @oagen-ignore-file
require "openssl"

module WorkOS
  module Util
    module Signature
      module_function

      def compute(payload:, timestamp:, secret:)
        OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{payload}")
      end

      def parse_header(sig_header)
        raise ArgumentError, "Signature header missing" if sig_header.nil? || sig_header.empty?

        parts = sig_header.split(",").map(&:strip)
        timestamp = parts.find { |part| part.start_with?("t=") }&.sub(/\At=/, "")
        signature = parts.find { |part| part.start_with?("v1=") }&.sub(/\Av1=/, "")
        raise ArgumentError, "Unable to extract timestamp and signature hash from header" if timestamp.nil? || signature.nil?

        [timestamp, signature]
      end

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
