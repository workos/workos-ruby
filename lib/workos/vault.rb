# frozen_string_literal: true

# @oagen-ignore-file
# Hand-maintained Vault service: 8 KV endpoints + 2 key endpoints + client-side
# AES-GCM encrypt/decrypt (H18). The Vault HTTP API is not in the OpenAPI spec
# and the AES-GCM helpers are inherently client-side, so this stays
# hand-maintained regardless of spec coverage.
require "base64"
require "json"
require "openssl"
require "securerandom"

module WorkOS
  # WorkOS Vault: KV secret storage, server-managed key wrapping, and
  # client-side AES-GCM encrypt/decrypt.
  #
  #   client.vault.create_object(name: "api-key", value: "sk_...", key_context: { "tenant" => "t1" })
  #   client.vault.encrypt(data: "plaintext", key_context: { "tenant" => "t1" })
  class Vault
    DEFAULT_RESPONSE_LIMIT = 10

    DataKey = Struct.new(:id, :key, keyword_init: true) do
      def self.from_response(hash)
        new(id: hash["id"], key: hash["data_key"])
      end
    end

    DataKeyPair = Struct.new(:context, :data_key, :encrypted_keys, keyword_init: true) do
      def self.from_response(hash)
        new(
          context: hash["context"],
          data_key: DataKey.new(id: hash["id"], key: hash["data_key"]),
          encrypted_keys: hash["encrypted_keys"]
        )
      end
    end

    ObjectUpdateBy = Struct.new(:id, :name, keyword_init: true) do
      def self.from_hash(hash)
        return nil if hash.nil?
        new(id: hash["id"], name: hash["name"])
      end
    end

    ObjectMetadata = Struct.new(
      :context, :environment_id, :id, :key_id, :updated_at, :updated_by, :version_id,
      keyword_init: true
    ) do
      def self.from_hash(hash)
        new(
          context: hash["context"],
          environment_id: hash["environment_id"],
          id: hash["id"],
          key_id: hash["key_id"],
          updated_at: hash["updated_at"],
          updated_by: ObjectUpdateBy.from_hash(hash["updated_by"]),
          version_id: hash["version_id"]
        )
      end
    end

    VaultObject = Struct.new(:id, :name, :value, :metadata, keyword_init: true) do
      def self.from_hash(hash)
        new(
          id: hash["id"],
          name: hash["name"],
          value: hash["value"],
          metadata: hash["metadata"] ? ObjectMetadata.from_hash(hash["metadata"]) : nil
        )
      end
    end

    ObjectDigest = Struct.new(:id, :name, :updated_at, keyword_init: true) do
      def self.from_hash(hash)
        new(id: hash["id"], name: hash["name"], updated_at: hash["updated_at"])
      end
    end

    ObjectVersion = Struct.new(:id, :created_at, :current_version, keyword_init: true) do
      def self.from_hash(hash)
        new(id: hash["id"], created_at: hash["created_at"], current_version: hash["current_version"])
      end
    end

    def initialize(client)
      @client = client
    end

    # -- KV operations --------------------------------------------------------

    # Get a Vault object with the value decrypted.
    def read_object(object_id:, request_options: {})
      response = @client.request(method: :get, path: "/vault/v1/kv/#{WorkOS::Util.encode_path(object_id)}", auth: true, request_options: request_options)
      VaultObject.from_hash(JSON.parse(response.body))
    end

    # Get a Vault object by name with the value decrypted.
    def read_object_by_name(name:, request_options: {})
      response = @client.request(method: :get, path: "/vault/v1/kv/name/#{WorkOS::Util.encode_path(name)}", auth: true, request_options: request_options)
      VaultObject.from_hash(JSON.parse(response.body))
    end

    # Get a Vault object's metadata without decrypting the value.
    def get_object_metadata(object_id:, request_options: {})
      response = @client.request(method: :get, path: "/vault/v1/kv/#{WorkOS::Util.encode_path(object_id)}/metadata", auth: true, request_options: request_options)
      VaultObject.from_hash(JSON.parse(response.body))
    end

    # List encrypted Vault objects.
    # @return [Array<ObjectDigest>]
    def list_objects(limit: DEFAULT_RESPONSE_LIMIT, before: nil, after: nil, request_options: {})
      params = {"limit" => limit, "before" => before, "after" => after}.compact
      response = @client.request(method: :get, path: "/vault/v1/kv", auth: true, params: params, request_options: request_options)
      parsed = JSON.parse(response.body)
      (parsed["data"] || []).map { |item| ObjectDigest.from_hash(item) }
    end

    # List versions for a specific Vault object.
    # @return [Array<ObjectVersion>]
    def list_object_versions(object_id:, request_options: {})
      response = @client.request(method: :get, path: "/vault/v1/kv/#{WorkOS::Util.encode_path(object_id)}/versions", auth: true, request_options: request_options)
      parsed = JSON.parse(response.body)
      (parsed["data"] || []).map { |item| ObjectVersion.from_hash(item) }
    end

    # Create a new Vault encrypted object.
    def create_object(name:, value:, key_context:, request_options: {})
      body = {"name" => name, "value" => value, "key_context" => key_context}
      response = @client.request(method: :post, path: "/vault/v1/kv", auth: true, body: body, request_options: request_options)
      ObjectMetadata.from_hash(JSON.parse(response.body))
    end

    # Update an existing Vault object.
    def update_object(object_id:, value:, version_check: nil, request_options: {})
      body = {"value" => value, "version_check" => version_check}.compact
      response = @client.request(method: :put, path: "/vault/v1/kv/#{WorkOS::Util.encode_path(object_id)}", auth: true, body: body, request_options: request_options)
      VaultObject.from_hash(JSON.parse(response.body))
    end

    # Permanently delete a Vault encrypted object.
    def delete_object(object_id:, request_options: {})
      @client.request(method: :delete, path: "/vault/v1/kv/#{WorkOS::Util.encode_path(object_id)}", auth: true, request_options: request_options)
      nil
    end

    # -- Key operations -------------------------------------------------------

    # Generate a data key for local encryption.
    # @return [DataKeyPair]
    def create_data_key(key_context:, request_options: {})
      body = {"context" => key_context}
      response = @client.request(method: :post, path: "/vault/v1/keys/data-key", auth: true, body: body, request_options: request_options)
      DataKeyPair.from_response(JSON.parse(response.body))
    end

    # Decrypt encrypted data keys previously generated by create_data_key.
    # @return [DataKey]
    def decrypt_data_key(keys:, request_options: {})
      body = {"keys" => keys}
      response = @client.request(method: :post, path: "/vault/v1/keys/decrypt", auth: true, body: body, request_options: request_options)
      DataKey.from_response(JSON.parse(response.body))
    end

    # -- Client-side AES-GCM encrypt/decrypt (H18) ---------------------------

    # Encrypt data locally using AES-GCM with a data key derived from the context.
    # Returns base64(IV || TAG || LEB128(len(keyBlob)) || keyBlob || ciphertext).
    def encrypt(data:, key_context:, associated_data: nil)
      pair = create_data_key(key_context: key_context)
      key = Base64.decode64(pair.data_key.key)
      key_blob = Base64.decode64(pair.encrypted_keys)
      prefix = encode_u32_leb128(key_blob.bytesize)
      iv, ciphertext, tag = aes_gcm_encrypt(data.b, key, associated_data&.b)
      Base64.strict_encode64(iv + tag + prefix + key_blob + ciphertext)
    end

    # Decrypt data previously encrypted by `encrypt`.
    def decrypt(encrypted_data:, associated_data: nil)
      payload = Base64.decode64(encrypted_data)
      iv = payload.byteslice(0, 12)
      tag = payload.byteslice(12, 16)
      key_len, leb_len = decode_u32_leb128(payload.byteslice(28, payload.bytesize - 28))
      keys_index = 28 + leb_len
      key_blob = payload.byteslice(keys_index, key_len)
      ciphertext = payload.byteslice(keys_index + key_len, payload.bytesize - (keys_index + key_len))
      data_key = decrypt_data_key(keys: Base64.strict_encode64(key_blob))
      key = Base64.decode64(data_key.key)
      aes_gcm_decrypt(ciphertext, key, iv, tag, associated_data&.b)
    end

    private

    def aes_gcm_encrypt(plaintext, key, aad)
      cipher = OpenSSL::Cipher.new("aes-256-gcm").encrypt
      cipher.key = key
      iv = SecureRandom.random_bytes(12)
      cipher.iv = iv
      cipher.auth_data = aad if aad
      ciphertext = cipher.update(plaintext) + cipher.final
      [iv, ciphertext, cipher.auth_tag]
    end

    def aes_gcm_decrypt(ciphertext, key, iv, tag, aad)
      cipher = OpenSSL::Cipher.new("aes-256-gcm").decrypt
      cipher.key = key
      cipher.iv = iv
      cipher.auth_tag = tag
      cipher.auth_data = aad if aad
      result = cipher.update(ciphertext) + cipher.final
      result.force_encoding(Encoding::UTF_8)
    end

    def encode_u32_leb128(value)
      raise ArgumentError, "value must fit in u32" if value.negative? || value > 0xFFFFFFFF
      bytes = +""
      loop do
        byte = value & 0x7F
        value >>= 7
        byte |= 0x80 if value != 0
        bytes << byte.chr
        break if value.zero?
      end
      bytes
    end

    def decode_u32_leb128(buf)
      result = 0
      shift = 0
      buf.each_byte.with_index do |b, i|
        raise ArgumentError, "LEB128 overflow" if i > 4
        result |= (b & 0x7F) << shift
        return [result, i + 1] if (b & 0x80).zero?
        shift += 7
      end
      raise ArgumentError, "LEB128 not terminated"
    end
  end
end
