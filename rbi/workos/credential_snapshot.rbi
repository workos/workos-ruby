# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained signatures for lib/workos/credential_snapshot.rb

# typed: strong

module WorkOS
  class CredentialSnapshot < Data
    sig { returns(T::Hash[String, String]) }
    def headers; end

    # Any value that compares with `==`. It is handed back, unchanged, to
    # the credentials' `invalidate`.
    sig { returns(T.untyped) }
    def generation; end

    sig { returns(T::Boolean) }
    def recoverable; end

    sig { params(headers: T::Hash[String, String], generation: T.untyped, recoverable: T::Boolean).void }
    def initialize(headers:, generation:, recoverable:); end

    sig { returns(String) }
    def inspect; end

    sig { returns(String) }
    def to_s; end

    sig { params(printer: T.untyped).void }
    def pretty_print(printer); end
  end
end
