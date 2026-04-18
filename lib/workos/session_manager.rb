# frozen_string_literal: true

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

module WorkOS
  class SessionManager
    JWK_ALGORITHMS = ["RS256"].freeze

    # @deprecated Use {WorkOS::Encryptors::AesGcm::SEAL_VERSION} instead.
    SEAL_VERSION = 0x01

    # H04 success / failure shapes — kept minimal & frozen.
    class AuthSuccess
      RESERVED_KEYS = [
        :authenticated, :session_id, :organization_id, :role, :roles,
        :permissions, :entitlements, :user, :impersonator, :feature_flags
      ].freeze

      attr_reader(*RESERVED_KEYS)

      def initialize(
        authenticated:,
        session_id:,
        organization_id:,
        role:,
        roles:,
        permissions:,
        entitlements:,
        user:,
        impersonator:,
        feature_flags:,
        custom_claims: nil
      )
        @authenticated = authenticated
        @session_id = session_id
        @organization_id = organization_id
        @role = role
        @roles = roles
        @permissions = permissions
        @entitlements = entitlements
        @user = user
        @impersonator = impersonator
        @feature_flags = feature_flags
        @custom_claims = normalize_custom_claims(custom_claims)
      end

      def [](key)
        sym_key = key.to_sym
        return public_send(sym_key) if RESERVED_KEYS.include?(sym_key)

        @custom_claims[sym_key]
      end

      def to_h
        RESERVED_KEYS.to_h { |key| [key, public_send(key)] }.merge(@custom_claims)
      end

      def method_missing(name, *args, &block)
        return @custom_claims[name] if args.empty? && @custom_claims.key?(name)

        super
      end

      def respond_to_missing?(name, include_private = false)
        @custom_claims.key?(name) || super
      end

      private

      def normalize_custom_claims(custom_claims)
        return {} if custom_claims.nil?
        raise ArgumentError, "claim_extractor must return a Hash" unless custom_claims.is_a?(Hash)

        claims = custom_claims.each_with_object({}) do |(key, value), memo|
          sym_key = key.to_sym
          if RESERVED_KEYS.include?(sym_key)
            raise ArgumentError, "claim_extractor cannot overwrite reserved key #{sym_key.inspect}"
          end

          memo[sym_key] = value
        end
        claims.freeze
      end
    end
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
      @jwks_mutex = Mutex.new
    end

    attr_reader :client

    # H04 — Load a Session object from a sealed cookie.
    def load(seal_data:, cookie_password:)
      Session.new(self, seal_data: seal_data, cookie_password: cookie_password)
    end

    # H05 — Inline convenience: authenticate without manual Session construction.
    def authenticate(seal_data:, cookie_password:, &claim_extractor)
      load(seal_data: seal_data, cookie_password: cookie_password).authenticate(&claim_extractor)
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

    # Cached JWKS fetch (5-minute TTL, thread-safe).
    def fetch_jwks(now: Time.now)
      @jwks_mutex.synchronize do
        return @jwks_cache if @jwks_cache && @jwks_cache_at && (now - @jwks_cache_at) < 300
        response = @client.user_management.get_jwks(client_id: @client.client_id)
        @jwks_cache = {"keys" => response.keys.map(&:to_h)}
        @jwks_cache_at = now
        @jwks_cache
      end
    end
  end
end
