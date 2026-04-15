# frozen_string_literal: true

require "test_helper"

class TestAesGcm < WorkOS::TestCase
  def setup
    super
    @encryptor = WorkOS::Encryptors::AesGcm.new
    @key = "a" * 32
    @data = {access_token: "tok_123", user: {id: "user_01"}}
  end

  def test_seal_returns_a_base64_encoded_string
    sealed = @encryptor.seal(@data, @key)
    assert_kind_of String, sealed
    Base64.decode64(sealed) # should not raise
  end

  def test_seal_produces_different_output_each_time
    sealed1 = @encryptor.seal(@data, @key)
    sealed2 = @encryptor.seal(@data, @key)
    refute_equal sealed1, sealed2
  end

  def test_unseal_round_trips_data_correctly
    sealed = @encryptor.seal(@data, @key)
    unsealed = @encryptor.unseal(sealed, @key)
    assert_equal @data, unsealed
  end

  def test_unseal_returns_hash_with_symbolized_keys
    sealed = @encryptor.seal({"string_key" => "value"}, @key)
    unsealed = @encryptor.unseal(sealed, @key)
    assert_kind_of Symbol, unsealed.keys.first
  end

  def test_unseal_raises_error_with_wrong_key
    sealed = @encryptor.seal(@data, @key)
    assert_raises(OpenSSL::Cipher::CipherError) do
      @encryptor.unseal(sealed, "b" * 32)
    end
  end
end
