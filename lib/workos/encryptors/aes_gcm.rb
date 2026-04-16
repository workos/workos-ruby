# @oagen-ignore-file
# Default AES-256-GCM encryptor for sealed session cookies.
# Implements the seal/unseal interface expected by SessionManager.

require "base64"
require "digest"
require "json"
require "openssl"
require "securerandom"

module WorkOS
  module Encryptors
    class AesGcm
      SEAL_VERSION = 0x01

      def seal(data, key)
        json = data.is_a?(String) ? data : JSON.generate(data)
        cipher = OpenSSL::Cipher.new("aes-256-gcm").encrypt
        cipher.key = derive_key(key)
        iv = SecureRandom.random_bytes(12)
        cipher.iv = iv
        ciphertext = cipher.update(json) + cipher.final
        Base64.strict_encode64(SEAL_VERSION.chr + iv + cipher.auth_tag + ciphertext)
      end

      def unseal(sealed, key)
        raw = Base64.decode64(sealed.to_s)
        raise ArgumentError, "Sealed payload too short" if raw.bytesize < 1 + 12 + 16
        version = raw.byteslice(0, 1).bytes.first
        raise ArgumentError, "Unknown seal version: #{version}" unless version == SEAL_VERSION
        iv = raw.byteslice(1, 12)
        tag = raw.byteslice(13, 16)
        ciphertext = raw.byteslice(29, raw.bytesize - 29)
        cipher = OpenSSL::Cipher.new("aes-256-gcm").decrypt
        cipher.key = derive_key(key)
        cipher.iv = iv
        cipher.auth_tag = tag
        decoded = cipher.update(ciphertext) + cipher.final
        decoded.force_encoding(Encoding::UTF_8)
        begin
          JSON.parse(decoded)
        rescue JSON::ParserError
          decoded
        end
      end

      private

      def derive_key(passphrase)
        Digest::SHA256.digest(passphrase.to_s)
      end
    end
  end
end
