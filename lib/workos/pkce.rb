# @oagen-ignore-file
# Hand-maintained PKCE utilities (H08).
# RFC 7636: code_verifier is 43-128 chars (high-entropy); code_challenge is
# the URL-safe base64 SHA-256 of the verifier (S256 method).

require "base64"
require "digest"
require "securerandom"

module WorkOS
  # PKCE (Proof Key for Code Exchange) utilities for OAuth public-client flows.
  #
  #   WorkOS::PKCE.generate_code_verifier      # => "abc..."
  #   WorkOS::PKCE.generate_code_challenge(v)  # => "xyz..."
  #   WorkOS::PKCE.generate_pair               # => { code_verifier:, code_challenge: }
  module PKCE
    # Default verifier length in bytes BEFORE base64url encoding. 32 bytes
    # → 43 characters of base64url, which is the RFC 7636 minimum.
    DEFAULT_VERIFIER_BYTES = 32

    module_function

    # Generate a cryptographically random PKCE code verifier.
    def generate_code_verifier(byte_length = DEFAULT_VERIFIER_BYTES)
      Base64.urlsafe_encode64(SecureRandom.random_bytes(byte_length), padding: false)
    end

    # Compute the S256 code_challenge for a given verifier.
    def generate_code_challenge(code_verifier)
      Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
    end

    # Generate a fresh (verifier, challenge) pair.
    # @return [Hash] { code_verifier:, code_challenge: }
    def generate_pair
      verifier = generate_code_verifier
      {code_verifier: verifier, code_challenge: generate_code_challenge(verifier)}
    end
  end
end
