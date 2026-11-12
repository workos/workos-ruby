# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained signatures for lib/workos/workload_identity.rb

# typed: strong

module WorkOS
  module WorkloadIdentity
    ENVIRONMENT_HEADER = T.let(T.unsafe(nil), String)
    GRANT_TYPE = T.let(T.unsafe(nil), String)
    DEFAULT_RESOURCE = T.let(T.unsafe(nil), String)
    REFRESH_THRESHOLD = T.let(T.unsafe(nil), Integer)
    REFRESH_FRACTION = T.let(T.unsafe(nil), Float)
    DEFAULT_LIFETIME = T.let(T.unsafe(nil), Integer)
    EXCHANGE_DEADLINE = T.let(T.unsafe(nil), Integer)

    sig { params(path: T.any(String, Pathname)).returns(T.proc.returns(String)) }
    def self.token_file(path); end

    sig { params(name: String).returns(T.proc.returns(String)) }
    def self.token_env(name); end
  end
end
