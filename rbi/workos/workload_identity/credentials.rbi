# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained signatures for lib/workos/workload_identity/credentials.rb

# typed: strong

module WorkOS
  module WorkloadIdentity
    class Credentials
      sig { returns(String) }
      def client_id; end

      sig { returns(String) }
      def token_url; end

      # Optional: nil when no environment ID was passed and
      # `WORKOS_ENVIRONMENT_ID` is unset or empty.
      sig { returns(T.nilable(String)) }
      def environment_id; end

      sig { returns(String) }
      def resource; end

      sig { returns(T.nilable(String)) }
      def scope; end

      # `identity_token_provider`, `clock` and `sleeper` are anything that
      # responds to `call` (a lambda, a Method, a provider object), so they
      # are left untyped.
      sig do
        params(
          identity_token_provider: T.untyped,
          client_id: T.nilable(String),
          token_url: T.nilable(String),
          environment_id: T.nilable(String),
          resource: T.nilable(String),
          scope: T.nilable(String),
          clock: T.untyped,
          sleeper: T.untyped,
          random: Random
        ).void
      end
      def initialize(identity_token_provider: nil, client_id: nil, token_url: nil, environment_id: nil, resource: nil, scope: nil, clock: nil, sleeper: nil, random: Random.new); end

      sig { params(timeout: T.nilable(Numeric)).returns(WorkOS::CredentialSnapshot) }
      def resolve(timeout: nil); end

      sig { params(generation: T.untyped).void }
      def invalidate(generation); end

      sig { returns(String) }
      def inspect; end
    end
  end
end
