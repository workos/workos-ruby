# @oagen-ignore-file
# Hand-maintained session-cookie helpers (H04-H07, H13):
#   - SessionManager#load(seal_data:, cookie_password:)  -> Session (H04)
#   - SessionManager#authenticate / #refresh             -> inline convenience (H05)
#   - SessionManager#seal_data / #unseal_data            -> raw seal/unseal (H06)
#   - SessionManager#seal_session_from_auth_response     -> H07
#   - Session#authenticate / #refresh / #get_logout_url
#
# Symmetric encryption: AES-256-GCM by default. Users may supply a custom
# encryptor (any object responding to `seal(data, key)` and `unseal(sealed, key)`)
# for compatibility with other sealing formats (e.g. Iron/Next.js).

require "json"
require "jwt"
require "net/http"
require "uri"

module WorkOS
  class SessionManager
    JWK_ALGORITHMS = ["RS256"].freeze

    # @deprecated Use {WorkOS::Encryptors::AesGcm::SEAL_VERSION} instead.
    SEAL_VERSION = 0x01

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

    # @param client [WorkOS::Client]
    # @param encryptor [#seal, #unseal] Optional custom encryptor. Defaults to
    #   {WorkOS::Encryptors::AesGcm}. A custom encryptor must respond to
    #   `seal(data, key) -> String` and `unseal(sealed_string, key) -> Hash`.
    def initialize(client, encryptor: nil)
      @client = client
      @encryptor = encryptor || Encryptors::AesGcm.new
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

    # H06 — Raw seal: encrypt arbitrary data with a key string.
    # Delegates to the configured encryptor (default: AES-256-GCM).
    def seal_data(data, key)
      @encryptor.seal(data, key)
    end

    # H06 — Raw unseal: returns parsed JSON (Hash) or raw string if not JSON.
    # Delegates to the configured encryptor (default: AES-256-GCM).
    def unseal_data(sealed, key)
      @encryptor.unseal(sealed, key)
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
  end
end
