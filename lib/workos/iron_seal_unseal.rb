# frozen_string_literal: true

module WorkOS
  # Seals and unseals session data using the Iron (Fe26.2) format compatible with iron-webcrypto.
  # Use as an optional algorithm for WorkOS::Session.seal_data / unseal_data via algorithm: :iron.
  module IronSealUnseal
    MAC_PREFIX = 'Fe26.2'
    DELIMITER = '*'
    VERSION_DELIMITER = '~'
    TIMESTAMP_SKEW_SEC = 60
    DEFAULT_TTL_SEC = 120

    class UnsealError < StandardError; end

    class << self
      # Seal data in Fe26.2 format (compatible with iron-webcrypto).
      # @param data [Hash] The data to seal (will be JSON-encoded)
      # @param password [String] Password (must be at least 32 characters)
      # @param ttl_sec [Integer] Time-to-live in seconds (default: 120)
      # @return [String] The sealed string
      def seal(data, password, ttl_sec: DEFAULT_TTL_SEC)
        raise ArgumentError, 'password must be at least 32 characters' if password.to_s.length < 32

        expiration_ms = ((Time.now + ttl_sec).to_f * 1000).to_i
        prefix = MAC_PREFIX
        password_id = ''
        encryption_salt = SecureRandom.base64(16).tr('+/', '-_').delete('=')
        hmac_salt = SecureRandom.base64(16).tr('+/', '-_').delete('=')
        iv = SecureRandom.random_bytes(16)
        encryption_key = derive_key(password, encryption_salt, 32)
        cipher = OpenSSL::Cipher.new('aes-256-cbc')
        cipher.encrypt
        cipher.key = encryption_key
        cipher.iv = iv
        payload = data.is_a?(String) ? data : data.to_json
        encrypted = cipher.update(payload) + cipher.final
        encryption_iv_b64 = Base64.urlsafe_encode64(iv).delete('=')
        encrypted_b64 = Base64.urlsafe_encode64(encrypted).delete('=')
        expiration = expiration_ms.to_s
        mac_base_string = [prefix, password_id, encryption_salt, encryption_iv_b64, encrypted_b64, expiration].join(DELIMITER)
        integrity_key = derive_key(password, hmac_salt, 32)
        hmac = OpenSSL::HMAC.digest('SHA256', integrity_key, mac_base_string)
        hmac_b64 = Base64.urlsafe_encode64(hmac).delete('=')
        [prefix, password_id, encryption_salt, encryption_iv_b64, encrypted_b64, expiration, hmac_salt, hmac_b64].join(DELIMITER)
      end

      # Unseal data sealed in Fe26.2 format.
      # @param sealed [String] Full cookie value (may include "~2" suffix from iron-session)
      # @param password [String] Password (or Hash of password_id => password)
      # @param skip_expiration [Boolean] If true, ignore TTL (default: false)
      # @return [Hash] Decoded session with symbolized keys
      # @raise [UnsealError] on invalid/expired seal or wrong password
      def unseal(sealed, password, skip_expiration: false)
        raise ArgumentError, 'password must be at least 32 characters' if password.is_a?(String) && password.to_s.length < 32

        inner_seal = sealed.to_s.split(VERSION_DELIMITER).first
        parts = inner_seal.split(DELIMITER)
        raise UnsealError, 'Incorrect number of sealed components (expected 8)' unless parts.length == 8

        prefix, password_id, encryption_salt, encryption_iv_b64, encrypted_b64, expiration, hmac_salt, hmac_b64 = parts
        raise UnsealError, "Wrong mac prefix (expected #{MAC_PREFIX})" unless prefix == MAC_PREFIX

        unless skip_expiration
          if expiration.to_s.match?(/\A\d+\z/)
            exp_ms = expiration.to_i
            now_ms = (Time.now.to_f * 1000).to_i
            raise UnsealError, 'Expired seal' if exp_ms <= now_ms - (TIMESTAMP_SKEW_SEC * 1000)
          end
        end

        pass = resolve_password(password, password_id)
        mac_base_string = [prefix, password_id, encryption_salt, encryption_iv_b64, encrypted_b64, expiration].join(DELIMITER)

        integrity_key = derive_key(pass, hmac_salt, 32)
        expected_hmac = OpenSSL::HMAC.digest('SHA256', integrity_key, mac_base_string)
        expected_hmac_b64 = base64url_encode(expected_hmac)
        raise UnsealError, 'Bad hmac value' unless secure_compare(hmac_b64, expected_hmac_b64)

        encryption_key = derive_key(pass, encryption_salt, 32)
        iv = base64url_decode(encryption_iv_b64)
        encrypted = base64url_decode(encrypted_b64)

        decrypted = aes256_cbc_decrypt(encryption_key, iv, encrypted)
        JSON.parse(decrypted, symbolize_names: true)
      end

      private

      def resolve_password(password, password_id)
        return password if password.is_a?(String)
        raise UnsealError, "Cannot find password: #{password_id}" unless password[password_id]

        password[password_id]
      end

      def derive_key(password, salt, key_length)
        OpenSSL::KDF.pbkdf2_hmac(
          password,
          salt: salt,
          iterations: 1,
          length: key_length,
          hash: OpenSSL::Digest.new('SHA1'),
        )
      end

      def aes256_cbc_decrypt(key, iv, ciphertext)
        cipher = OpenSSL::Cipher.new('aes-256-cbc')
        cipher.decrypt
        cipher.key = key
        cipher.iv = iv
        cipher.update(ciphertext) + cipher.final
      end

      def base64url_decode(str)
        padding = (4 - str.length % 4) % 4
        Base64.urlsafe_decode64(str + ('=' * padding))
      end

      def base64url_encode(bytes)
        Base64.urlsafe_encode64(bytes).delete('=')
      end

      def secure_compare(a, b)
        return false unless a.bytesize == b.bytesize

        l = a.unpack('C*')
        r = b.unpack('C*')
        result = 0
        l.zip(r) { |x, y| result |= x ^ y }
        result.zero?
      end
    end
  end
end
