# frozen_string_literal: true

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
      # Minimum cookie_password byte length. AES-256-GCM derives a 32-byte
      # key from the password via SHA-256; a passphrase shorter than the
      # output it derives to provides less than the full keyspace and makes
      # offline brute-force feasible. See README + V7_MIGRATION_GUIDE.md.
      MIN_KEY_BYTES = 32

      def seal(data, key)
        validate_key!(key)
        json = data.is_a?(String) ? data : JSON.generate(data)
        cipher = OpenSSL::Cipher.new("aes-256-gcm").encrypt
        cipher.key = derive_key(key)
        iv = SecureRandom.random_bytes(12)
        cipher.iv = iv
        ciphertext = cipher.update(json) + cipher.final
        Base64.strict_encode64(SEAL_VERSION.chr + iv + cipher.auth_tag + ciphertext)
      end

      def unseal(sealed, key)
        validate_key!(key)
        raw = Base64.decode64(sealed.to_s)
        begin
          decode_v7(raw, key)
        rescue ArgumentError, OpenSSL::Cipher::CipherError => original_error
          begin
            decode_old(raw, key)
          rescue ArgumentError, OpenSSL::Cipher::CipherError
            raise original_error
          end
        end
      end

      private

      def decode_v7(raw, key)
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

        parse_decoded(cipher.update(ciphertext) + cipher.final)
      end

      def decode_old(raw, key)
        # v6 sealed sessions were Base64(iv + ciphertext + auth_tag) using the
        # `encryptor` gem without the v7 version byte or key derivation.
        raise ArgumentError, "Legacy sealed payload too short" if raw.bytesize < 12 + 16

        iv = raw.byteslice(0, 12)
        encrypted = raw.byteslice(12, raw.bytesize - 12)
        ciphertext = encrypted.byteslice(0, encrypted.bytesize - 16)
        tag = encrypted.byteslice(encrypted.bytesize - 16, 16)

        cipher = OpenSSL::Cipher.new("aes-256-gcm").decrypt
        cipher.key = key.to_s
        cipher.iv = iv
        cipher.auth_tag = tag

        parse_decoded(cipher.update(ciphertext) + cipher.final)
      end

      def parse_decoded(decoded)
        decoded.force_encoding(Encoding::UTF_8)
        begin
          JSON.parse(decoded)
        rescue JSON::ParserError
          decoded
        end
      end

      def derive_key(passphrase)
        Digest::SHA256.digest(passphrase.to_s)
      end

      def validate_key!(key)
        raise ArgumentError, "cookie_password is required" if key.nil? || key.to_s.empty?
        raise ArgumentError, "cookie_password must be at least #{MIN_KEY_BYTES} bytes" if key.to_s.bytesize < MIN_KEY_BYTES
      end
    end
  end
end
