# frozen_string_literal: true

require 'encryptor'
require 'securerandom'
require 'json'
require 'base64'

module WorkOS
  module Encryptors
    # Default encryptor using AES-256-GCM.
    # Implements the encryptor interface: #seal(data, key) and #unseal(sealed_data, key)
    class AesGcm
      # Encrypts and seals data using AES-256-GCM
      # @param data [Hash] The data to seal
      # @param key [String] The encryption key
      # @return [String] Base64-encoded sealed data
      def seal(data, key)
        iv = SecureRandom.random_bytes(12)

        encrypted_data = Encryptor.encrypt(
          value: JSON.generate(data),
          key: key,
          iv: iv,
          algorithm: 'aes-256-gcm',
        )
        Base64.encode64(iv + encrypted_data)
      end

      # Decrypts and unseals data using AES-256-GCM
      # @param sealed_data [String] The sealed data to unseal
      # @param key [String] The decryption key
      # @return [Hash] The unsealed data with symbolized keys
      def unseal(sealed_data, key)
        decoded_data = Base64.decode64(sealed_data)
        iv = decoded_data[0..11]
        encrypted_data = decoded_data[12..]

        decrypted_data = Encryptor.decrypt(
          value: encrypted_data,
          key: key,
          iv: iv,
          algorithm: 'aes-256-gcm',
        )

        JSON.parse(decrypted_data, symbolize_names: true)
      end
    end
  end
end
