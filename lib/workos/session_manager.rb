# @oagen-ignore-file
# Hand-maintained session-cookie helpers (H04-H07, H13):
#   - SessionManager#load(seal_data:, cookie_password:)  -> Session (H04)
#   - SessionManager#authenticate / #refresh             -> inline convenience (H05)
#   - SessionManager#seal_data / #unseal_data            -> raw seal/unseal (H06)
#   - SessionManager#seal_session_from_auth_response     -> H07
#   - Session#authenticate / #refresh / #get_logout_url
#
# Symmetric encryption: AES-256-GCM. The `cookie_password` is hashed with
# SHA-256 to produce a 32-byte key. Sealed format (base64-encoded):
#   [VERSION(1) || IV(12) || TAG(16) || CIPHERTEXT]

require "base64"
require "digest"
require "json"
require "jwt"
require "net/http"
require "openssl"
require "securerandom"
require "uri"

module WorkOS
  class SessionManager
    SEAL_VERSION = 0x01
    JWK_ALGORITHMS = ["RS256"].freeze

    # H04 success / failure shapes — kept minimal & frozen.
    AuthSuccess = Struct.new(
      :authenticated, :session_id, :organization_id, :role, :roles,
      :permissions, :entitlements, :user, :impersonator, :feature_flags,
      keyword_init: true
    )
    AuthError = Struct.new(:authenticated, :reason, keyword_init: true)

    RefreshSuccess = Struct.new(
      :authenticated, :sealed_session, :session_id, :organization_id, :role,
      :roles, :permissions, :entitlements, :user, :impersonator, :feature_flags,
      keyword_init: true
    )
    RefreshError = Struct.new(:authenticated, :reason, keyword_init: true)

    # Failure reason constants
    NO_SESSION_COOKIE_PROVIDED = "no_session_cookie_provided"
    INVALID_SESSION_COOKIE = "invalid_session_cookie"
    INVALID_JWT = "invalid_jwt"

    def initialize(client)
      @client = client
      @jwks_cache = nil
      @jwks_cache_at = nil
    end

    # H04 — Load a Session object from a sealed cookie.
    def load(seal_data:, cookie_password:)
      Session.new(self, seal_data: seal_data, cookie_password: cookie_password)
    end

    # H05 — Inline convenience: authenticate without manual Session construction.
    def authenticate(seal_data:, cookie_password:)
      load(seal_data: seal_data, cookie_password: cookie_password).authenticate
    end

    # H05 — Inline convenience: refresh without manual Session construction.
    def refresh(seal_data:, cookie_password:, organization_id: nil)
      load(seal_data: seal_data, cookie_password: cookie_password)
        .refresh(organization_id: organization_id)
    end

    # H06 — Raw seal: AES-256-GCM encrypt arbitrary data with a key string.
    # Returns base64(VERSION || IV || TAG || CIPHERTEXT).
    def seal_data(data, key)
      json = data.is_a?(String) ? data : JSON.generate(data)
      cipher = OpenSSL::Cipher.new("aes-256-gcm").encrypt
      cipher.key = derive_key(key)
      iv = SecureRandom.random_bytes(12)
      cipher.iv = iv
      ciphertext = cipher.update(json) + cipher.final
      Base64.strict_encode64(SEAL_VERSION.chr + iv + cipher.auth_tag + ciphertext)
    end

    # H06 — Raw unseal: returns parsed JSON (Hash) or raw string if not JSON.
    def unseal_data(sealed, key)
      raw = Base64.decode64(sealed.to_s)
      raise ArgumentError, "Sealed payload too short" if raw.bytesize < 1 + 12 + 16
      version = raw.byteslice(0, 1).bytes.first
      raise ArgumentError, "Unknown seal version: #{version}" unless version == SEAL_VERSION
      iv = raw.byteslice(1, 12)
      tag = raw.byteslice(13, 16)
      ciphertext = raw.byteslice(29, raw.bytesize - 29)
      cipher = OpenSSL::Cipher.new("aes-256-gcm").decrypt
      cipher.key = derive_key(key)
      cipher.iv = iv
      cipher.auth_tag = tag
      decoded = cipher.update(ciphertext) + cipher.final
      decoded.force_encoding(Encoding::UTF_8)
      begin
        JSON.parse(decoded)
      rescue JSON::ParserError
        decoded
      end
    end

    # H07 — Build a sealed session string directly from auth-response fields.
    def seal_session_from_auth_response(access_token:, refresh_token:, cookie_password:, user: nil, impersonator: nil)
      payload = {"access_token" => access_token, "refresh_token" => refresh_token}
      payload["user"] = user if user
      payload["impersonator"] = impersonator if impersonator
      seal_data(payload, cookie_password)
    end

    # Verify an access-token JWT against the WorkOS JWKS for this client.
    # Used by Session#authenticate; exposed publicly for advanced cases.
    def decode_jwt(access_token)
      jwks = fetch_jwks
      JWT.decode(
        access_token,
        nil,
        true,
        algorithms: JWK_ALGORITHMS,
        jwks: jwks,
        verify_aud: false
      ).first
    end

    # Cached JWKS fetch (5-minute TTL).
    def fetch_jwks(now: Time.now)
      return @jwks_cache if @jwks_cache && @jwks_cache_at && (now - @jwks_cache_at) < 300
      uri = URI(@client.user_management.get_jwks_url)
      raw = Net::HTTP.get(uri)
      @jwks_cache = JSON.parse(raw)
      @jwks_cache_at = now
      @jwks_cache
    end

    private

    def derive_key(passphrase)
      Digest::SHA256.digest(passphrase.to_s)
    end
  end
end
