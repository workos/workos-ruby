# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained signatures for lib/workos/static_key_credentials.rb

# typed: strong

module WorkOS
  class StaticKeyCredentials
    sig { params(api_key: T.nilable(String)).void }
    def initialize(api_key); end

    sig { params(timeout: T.nilable(Numeric)).returns(WorkOS::CredentialSnapshot) }
    def resolve(timeout: nil); end

    sig { params(_generation: T.untyped).void }
    def invalidate(_generation); end

    sig { returns(String) }
    def inspect; end
  end
end
