# @oagen-ignore-file
require "test_helper"
require "base64"

class VaultTest < Minitest::Test
  def setup
    @client = WorkOS::Client.new(api_key: "sk_test_vault")
  end

  def test_vault_accessor_exists
    assert_kind_of WorkOS::Vault, @client.vault
  end

  def test_create_object_returns_metadata
    body = {
      "id" => "obj_01", "key_id" => "key_01", "version_id" => "v1",
      "context" => {"tenant" => "t1"}, "environment_id" => "env_1",
      "updated_at" => "2026-04-15T00:00:00Z",
      "updated_by" => {"id" => "u1", "name" => "alice"}
    }
    stub_request(:post, "https://api.workos.com/vault/v1/kv")
      .with(body: hash_including("name" => "secret", "value" => "hello"))
      .to_return(status: 200, body: body.to_json)

    meta = @client.vault.create_object(name: "secret", value: "hello", key_context: {"tenant" => "t1"})
    assert_equal "obj_01", meta.id
    assert_equal "v1", meta.version_id
    assert_equal "alice", meta.updated_by.name
  end

  def test_read_object_returns_decrypted_value
    body = {
      "id" => "obj_01", "name" => "secret", "value" => "hello",
      "metadata" => {
        "id" => "obj_01", "key_id" => "k", "version_id" => "v",
        "context" => {}, "environment_id" => "env",
        "updated_at" => "x", "updated_by" => {"id" => "u", "name" => "n"}
      }
    }
    stub_request(:get, "https://api.workos.com/vault/v1/kv/obj_01")
      .to_return(status: 200, body: body.to_json)

    obj = @client.vault.read_object(object_id: "obj_01")
    assert_equal "hello", obj.value
    assert_equal "secret", obj.name
  end

  def test_list_objects_returns_digests
    body = {"data" => [{"id" => "o1", "name" => "a", "updated_at" => "x"}, {"id" => "o2", "name" => "b", "updated_at" => "y"}]}
    stub_request(:get, /vault\/v1\/kv\?/).to_return(status: 200, body: body.to_json)

    digests = @client.vault.list_objects(limit: 10)
    assert_equal 2, digests.size
    assert_equal "o1", digests.first.id
  end

  def test_list_object_versions
    body = {"data" => [{"id" => "v1", "created_at" => "x", "current_version" => true}]}
    stub_request(:get, "https://api.workos.com/vault/v1/kv/obj_1/versions").to_return(status: 200, body: body.to_json)

    versions = @client.vault.list_object_versions(object_id: "obj_1")
    assert_equal 1, versions.size
    assert versions.first.current_version
  end

  def test_get_object_metadata
    body = {"id" => "obj_1", "name" => "n", "metadata" => {
      "id" => "obj_1", "key_id" => "k", "version_id" => "v",
      "context" => {}, "environment_id" => "env",
      "updated_at" => "x", "updated_by" => {"id" => "u", "name" => "n"}
    }}
    stub_request(:get, "https://api.workos.com/vault/v1/kv/obj_1/metadata").to_return(status: 200, body: body.to_json)

    obj = @client.vault.get_object_metadata(object_id: "obj_1")
    assert_nil obj.value
    assert_equal "obj_1", obj.metadata.id
  end

  def test_delete_object_returns_nil
    stub_request(:delete, "https://api.workos.com/vault/v1/kv/obj_1").to_return(status: 200, body: "")
    assert_nil @client.vault.delete_object(object_id: "obj_1")
  end

  def test_update_object_with_version_check
    body = {"id" => "obj_1", "name" => "n", "value" => "newval", "metadata" => nil}
    stub_request(:put, "https://api.workos.com/vault/v1/kv/obj_1")
      .with(body: hash_including("value" => "newval", "version_check" => "v1"))
      .to_return(status: 200, body: body.to_json)

    obj = @client.vault.update_object(object_id: "obj_1", value: "newval", version_check: "v1")
    assert_equal "newval", obj.value
  end

  def test_create_data_key
    body = {"context" => {"t" => "1"}, "id" => "dek_1", "data_key" => Base64.strict_encode64("k" * 32), "encrypted_keys" => Base64.strict_encode64("blob")}
    stub_request(:post, "https://api.workos.com/vault/v1/keys/data-key")
      .with(body: hash_including("context" => {"t" => "1"}))
      .to_return(status: 200, body: body.to_json)

    pair = @client.vault.create_data_key(key_context: {"t" => "1"})
    assert_equal "dek_1", pair.data_key.id
    assert_equal "blob", Base64.decode64(pair.encrypted_keys)
  end

  def test_decrypt_data_key
    body = {"id" => "dek_1", "data_key" => Base64.strict_encode64("k" * 32)}
    stub_request(:post, "https://api.workos.com/vault/v1/keys/decrypt")
      .with(body: hash_including("keys" => "abc"))
      .to_return(status: 200, body: body.to_json)

    dk = @client.vault.decrypt_data_key(keys: "abc")
    assert_equal "dek_1", dk.id
  end

  def test_local_encrypt_then_decrypt_roundtrip
    plaintext_key = "k" * 32
    create_resp = {"context" => {"t" => "1"}, "id" => "dek_1",
                   "data_key" => Base64.strict_encode64(plaintext_key),
                   "encrypted_keys" => Base64.strict_encode64("ENCRYPTED_BLOB")}
    decrypt_resp = {"id" => "dek_1", "data_key" => Base64.strict_encode64(plaintext_key)}

    stub_request(:post, "https://api.workos.com/vault/v1/keys/data-key").to_return(status: 200, body: create_resp.to_json)
    stub_request(:post, "https://api.workos.com/vault/v1/keys/decrypt").to_return(status: 200, body: decrypt_resp.to_json)

    payload = "the quick brown fox"
    encrypted = @client.vault.encrypt(data: payload, key_context: {"t" => "1"})
    refute_equal payload, encrypted

    plaintext = @client.vault.decrypt(encrypted_data: encrypted)
    assert_equal payload, plaintext
  end

  def test_local_encrypt_with_associated_data
    plaintext_key = "k" * 32
    create_resp = {"context" => {}, "id" => "dek", "data_key" => Base64.strict_encode64(plaintext_key), "encrypted_keys" => Base64.strict_encode64("BLOB")}
    decrypt_resp = {"id" => "dek", "data_key" => Base64.strict_encode64(plaintext_key)}

    stub_request(:post, "https://api.workos.com/vault/v1/keys/data-key").to_return(status: 200, body: create_resp.to_json)
    stub_request(:post, "https://api.workos.com/vault/v1/keys/decrypt").to_return(status: 200, body: decrypt_resp.to_json)

    encrypted = @client.vault.encrypt(data: "secret", key_context: {}, associated_data: "tenant=42")
    plaintext = @client.vault.decrypt(encrypted_data: encrypted, associated_data: "tenant=42")
    assert_equal "secret", plaintext

    assert_raises(OpenSSL::Cipher::CipherError) do
      @client.vault.decrypt(encrypted_data: encrypted, associated_data: "wrong")
    end
  end
end
