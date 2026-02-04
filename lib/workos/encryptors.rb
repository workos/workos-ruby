# frozen_string_literal: true

module WorkOS
  # Encryptors module provides pluggable encryption implementations for session data.
  # The default encryptor is AesGcm, which uses AES-256-GCM encryption.
  module Encryptors
    autoload :AesGcm, 'workos/encryptors/aes_gcm'
  end
end
