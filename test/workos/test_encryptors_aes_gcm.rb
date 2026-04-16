# @oagen-ignore-file
require "test_helper"
require "base64"

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
    assert_raises(OpenSSL::Cipher::CipherError) do
      @enc.unseal(sealed, "wrong-password")
    end
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
end
