# @oagen-ignore-file
require "test_helper"
require "base64"
require "digest"

class PKCETest < Minitest::Test
  def test_module_accessible_from_client
    client = WorkOS::Client.new(api_key: "k")
    assert_equal WorkOS::PKCE, client.pkce
  end

  def test_generate_code_verifier_meets_rfc7636_minimum
    v = WorkOS::PKCE.generate_code_verifier
    assert v.length >= 43, "verifier too short: #{v.length}"
    assert v.length <= 128, "verifier too long: #{v.length}"
    assert_match(/\A[A-Za-z0-9_-]+\z/, v, "verifier must be base64url unreserved chars")
  end

  def test_generate_code_verifier_is_random
    refute_equal WorkOS::PKCE.generate_code_verifier, WorkOS::PKCE.generate_code_verifier
  end

  def test_generate_code_challenge_is_s256_of_verifier
    verifier = WorkOS::PKCE.generate_code_verifier
    expected = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
    assert_equal expected, WorkOS::PKCE.generate_code_challenge(verifier)
  end

  def test_generate_pair_is_self_consistent
    pair = WorkOS::PKCE.generate_pair
    expected = WorkOS::PKCE.generate_code_challenge(pair[:code_verifier])
    assert_equal expected, pair[:code_challenge]
  end

  def test_generate_pair_is_unique_per_call
    refute_equal WorkOS::PKCE.generate_pair[:code_verifier], WorkOS::PKCE.generate_pair[:code_verifier]
  end
end
