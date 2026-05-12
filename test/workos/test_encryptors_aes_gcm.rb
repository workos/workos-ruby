# frozen_string_literal: true

# @oagen-ignore-file
require "test_helper"
require "base64"
require "json"
require "openssl"
require "securerandom"

class EncryptorsAesGcmTest < Minitest::Test
  PASSWORD = "test-cookie-password-at-least-32"

  def setup
    @enc = WorkOS::Encryptors::AesGcm.new
  end

  def test_seal_unseal_round_trip_hash
    data = {"access_token" => "tok_abc", "refresh_token" => "ref_xyz"}
    sealed = @enc.seal(data, PASSWORD)
    assert_instance_of String, sealed
    assert_equal data, @enc.unseal(sealed, PASSWORD)
  end

  def test_seal_unseal_round_trip_string
    sealed = @enc.seal("hello world", PASSWORD)
    assert_equal "hello world", @enc.unseal(sealed, PASSWORD)
  end

  def test_unseal_with_wrong_key_raises
    sealed = @enc.seal({"x" => 1}, PASSWORD)
    # Wrong key is the same length (>= 32 bytes) so the length guard doesn't
    # short-circuit; we want to assert the underlying cipher rejection.
    assert_raises(OpenSSL::Cipher::CipherError) do
      @enc.unseal(sealed, "wrong-cookie-password-32-bytes--")
    end
  end

  def test_unseal_rejects_short_key
    sealed = @enc.seal({"x" => 1}, PASSWORD)
    assert_raises(ArgumentError) do
      @enc.unseal(sealed, "too-short")
    end
  end

  def test_seal_rejects_short_key
    assert_raises(ArgumentError) { @enc.seal({"x" => 1}, "too-short") }
    assert_raises(ArgumentError) { @enc.seal({"x" => 1}, nil) }
    assert_raises(ArgumentError) { @enc.seal({"x" => 1}, "") }
  end

  def test_unseal_rejects_short_payload
    assert_raises(ArgumentError) do
      @enc.unseal(Base64.strict_encode64("short"), PASSWORD)
    end
  end

  def test_unseal_rejects_unknown_version
    sealed = @enc.seal("data", PASSWORD)
    raw = Base64.decode64(sealed)
    tampered = Base64.strict_encode64("\x99".b + raw.b[1..])
    assert_raises(ArgumentError) do
      @enc.unseal(tampered, PASSWORD)
    end
  end

  def test_each_seal_produces_unique_output
    data = {"key" => "value"}
    sealed1 = @enc.seal(data, PASSWORD)
    sealed2 = @enc.seal(data, PASSWORD)
    refute_equal sealed1, sealed2
  end

  def test_unseal_reads_legacy_v6_payload
    data = {"access_token" => "tok_abc", "refresh_token" => "ref_xyz"}
    sealed = legacy_v6_seal(data, PASSWORD)
    assert_equal data, @enc.unseal(sealed, PASSWORD)
  end

  private

  def legacy_v6_seal(data, key)
    cipher = OpenSSL::Cipher.new("aes-256-gcm").encrypt
    iv = SecureRandom.random_bytes(12)
    cipher.key = key
    cipher.iv = iv
    ciphertext = cipher.update(JSON.generate(data)) + cipher.final

    Base64.encode64(iv + ciphertext + cipher.auth_tag)
  end
end
