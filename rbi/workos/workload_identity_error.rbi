# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained signatures for WorkOS::WorkloadIdentityError in lib/workos/errors.rb

# typed: strong

module WorkOS
  class WorkloadIdentityError < Error
    DESCRIPTION_LIMIT = T.let(T.unsafe(nil), Integer)
    HINTS = T.let(T.unsafe(nil), T::Hash[String, String])
    DEFAULT_HINT = T.let(T.unsafe(nil), String)

    sig { returns(String) }
    def code; end

    sig { returns(String) }
    def description; end

    sig { returns(String) }
    def hint; end

    sig { params(code: T.any(String, Symbol), description: T.nilable(String)).void }
    def initialize(code:, description: nil); end
  end
end
