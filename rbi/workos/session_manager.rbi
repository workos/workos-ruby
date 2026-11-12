# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained signatures for lib/workos/session_manager.rb

# typed: strong

module WorkOS
  class SessionManager
    JWK_ALGORITHMS = T.let(["RS256"].freeze, T::Array[String])

    NO_SESSION_COOKIE_PROVIDED = T.let("no_session_cookie_provided", String)
    INVALID_SESSION_COOKIE = T.let("invalid_session_cookie", String)
    INVALID_JWT = T.let("invalid_jwt", String)
    INVALID_JWT_ALGORITHM = T.let("invalid_jwt_algorithm", String)
    INVALID_JWT_SIGNATURE = T.let("invalid_jwt_signature", String)
    EXPIRED_JWT = T.let("expired_jwt", String)

    class AuthSuccess
      RESERVED_KEYS = T.let(T.unsafe(nil), T::Array[Symbol])

      sig { returns(T::Boolean) }
      def authenticated; end

      sig { returns(T.nilable(String)) }
      def reason; end

      sig { returns(T.nilable(String)) }
      def session_id; end

      sig { returns(T.nilable(String)) }
      def organization_id; end

      sig { returns(T.nilable(String)) }
      def role; end

      sig { returns(T.nilable(T::Array[String])) }
      def roles; end

      sig { returns(T.nilable(T::Array[String])) }
      def permissions; end

      sig { returns(T.nilable(T::Array[String])) }
      def entitlements; end

      sig { returns(T.untyped) }
      def user; end

      sig { returns(T.untyped) }
      def impersonator; end

      sig { returns(T.untyped) }
      def feature_flags; end

      sig do
        params(
          authenticated: T::Boolean,
          session_id: T.nilable(String),
          organization_id: T.nilable(String),
          role: T.nilable(String),
          roles: T.nilable(T::Array[String]),
          permissions: T.nilable(T::Array[String]),
          entitlements: T.nilable(T::Array[String]),
          user: T.untyped,
          impersonator: T.untyped,
          feature_flags: T.untyped,
          reason: T.nilable(String),
          custom_claims: T.nilable(T::Hash[Symbol, T.untyped])
        ).void
      end
      def initialize(authenticated:, session_id:, organization_id:, role:, roles:, permissions:, entitlements:, user:, impersonator:, feature_flags:, reason: nil, custom_claims: nil); end

      sig { params(key: T.any(String, Symbol)).returns(T.untyped) }
      def [](key); end

      sig { returns(T::Hash[Symbol, T.untyped]) }
      def to_h; end
    end

    # The three result classes below are `Struct.new(..., keyword_init: true)`
    # in lib/: every member is an optional keyword of `new`, and has a reader
    # and a writer.
    class AuthError
      sig { returns(T::Boolean) }
      def authenticated; end

      sig { params(value: T::Boolean).returns(T::Boolean) }
      def authenticated=(value); end

      sig { returns(T.nilable(String)) }
      def reason; end

      sig { params(value: T.nilable(String)).returns(T.nilable(String)) }
      def reason=(value); end

      sig { params(authenticated: T::Boolean, reason: T.nilable(String)).void }
      def initialize(authenticated: T.unsafe(nil), reason: T.unsafe(nil)); end
    end

    class RefreshSuccess
      sig { returns(T::Boolean) }
      def authenticated; end

      sig { params(value: T::Boolean).returns(T::Boolean) }
      def authenticated=(value); end

      sig { returns(T.nilable(String)) }
      def sealed_session; end

      sig { params(value: T.nilable(String)).returns(T.nilable(String)) }
      def sealed_session=(value); end

      sig { returns(T.nilable(String)) }
      def session_id; end

      sig { params(value: T.nilable(String)).returns(T.nilable(String)) }
      def session_id=(value); end

      sig { returns(T.nilable(String)) }
      def organization_id; end

      sig { params(value: T.nilable(String)).returns(T.nilable(String)) }
      def organization_id=(value); end

      sig { returns(T.nilable(String)) }
      def role; end

      sig { params(value: T.nilable(String)).returns(T.nilable(String)) }
      def role=(value); end

      sig { returns(T.nilable(T::Array[String])) }
      def roles; end

      sig { params(value: T.nilable(T::Array[String])).returns(T.nilable(T::Array[String])) }
      def roles=(value); end

      sig { returns(T.nilable(T::Array[String])) }
      def permissions; end

      sig { params(value: T.nilable(T::Array[String])).returns(T.nilable(T::Array[String])) }
      def permissions=(value); end

      sig { returns(T.nilable(T::Array[String])) }
      def entitlements; end

      sig { params(value: T.nilable(T::Array[String])).returns(T.nilable(T::Array[String])) }
      def entitlements=(value); end

      sig { returns(T.untyped) }
      def user; end

      sig { params(value: T.untyped).returns(T.untyped) }
      def user=(value); end

      sig { returns(T.untyped) }
      def impersonator; end

      sig { params(value: T.untyped).returns(T.untyped) }
      def impersonator=(value); end

      sig { returns(T.untyped) }
      def feature_flags; end

      sig { params(value: T.untyped).returns(T.untyped) }
      def feature_flags=(value); end

      sig do
        params(
          authenticated: T::Boolean,
          sealed_session: T.nilable(String),
          session_id: T.nilable(String),
          organization_id: T.nilable(String),
          role: T.nilable(String),
          roles: T.nilable(T::Array[String]),
          permissions: T.nilable(T::Array[String]),
          entitlements: T.nilable(T::Array[String]),
          user: T.untyped,
          impersonator: T.untyped,
          feature_flags: T.untyped
        ).void
      end
      def initialize(authenticated: T.unsafe(nil), sealed_session: T.unsafe(nil), session_id: T.unsafe(nil), organization_id: T.unsafe(nil), role: T.unsafe(nil), roles: T.unsafe(nil), permissions: T.unsafe(nil), entitlements: T.unsafe(nil), user: T.unsafe(nil), impersonator: T.unsafe(nil), feature_flags: T.unsafe(nil)); end
    end

    class RefreshError
      sig { returns(T::Boolean) }
      def authenticated; end

      sig { params(value: T::Boolean).returns(T::Boolean) }
      def authenticated=(value); end

      sig { returns(T.nilable(String)) }
      def reason; end

      sig { params(value: T.nilable(String)).returns(T.nilable(String)) }
      def reason=(value); end

      # The cookie the refresh was attempted with, when the failure leaves it
      # usable.
      sig { returns(T.nilable(String)) }
      def sealed_session; end

      sig { params(value: T.nilable(String)).returns(T.nilable(String)) }
      def sealed_session=(value); end

      sig { params(authenticated: T::Boolean, reason: T.nilable(String), sealed_session: T.nilable(String)).void }
      def initialize(authenticated: T.unsafe(nil), reason: T.unsafe(nil), sealed_session: T.unsafe(nil)); end
    end

    sig { returns(WorkOS::Client) }
    def client; end

    sig { params(client: WorkOS::Client, encryptor: T.untyped).void }
    def initialize(client, encryptor: nil); end

    sig { params(seal_data: String, cookie_password: String).returns(WorkOS::Session) }
    def load(seal_data:, cookie_password:); end

    sig do
      params(
        seal_data: String,
        cookie_password: String,
        include_expired: T::Boolean,
        claim_extractor: T.nilable(T.proc.params(decoded: T::Hash[String, T.untyped]).returns(T.nilable(T::Hash[Symbol, T.untyped])))
      ).returns(T.any(WorkOS::SessionManager::AuthSuccess, WorkOS::SessionManager::AuthError))
    end
    def authenticate(seal_data:, cookie_password:, include_expired: false, &claim_extractor); end

    sig do
      params(
        seal_data: String,
        cookie_password: String,
        organization_id: T.nilable(String)
      ).returns(T.any(WorkOS::SessionManager::RefreshSuccess, WorkOS::SessionManager::RefreshError))
    end
    def refresh(seal_data:, cookie_password:, organization_id: nil); end

    sig { params(data: T.any(String, T::Hash[T.untyped, T.untyped]), key: String).returns(String) }
    def seal_data(data, key); end

    sig { params(sealed: String, key: String).returns(T.any(T::Hash[String, T.untyped], String)) }
    def unseal_data(sealed, key); end

    sig do
      params(
        access_token: String,
        refresh_token: String,
        cookie_password: String,
        user: T.untyped,
        impersonator: T.untyped
      ).returns(String)
    end
    def seal_session_from_auth_response(access_token:, refresh_token:, cookie_password:, user: nil, impersonator: nil); end

    sig { params(access_token: String, verify_expiration: T::Boolean).returns(T::Hash[String, T.untyped]) }
    def decode_jwt(access_token, verify_expiration: true); end

    sig { params(now: Time).returns(T::Hash[String, T.untyped]) }
    def fetch_jwks(now: Time.now); end
  end
end
