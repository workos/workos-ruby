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

    # No `initialize` here: the class is a `Data.define`, which takes its
    # members by position or by keyword. Sorbet models that itself and
    # rejects a keyword-only redefinition.

    sig { returns(String) }
    def inspect; end

    alias_method :to_s, :inspect

    sig { params(printer: T.untyped).void }
    def pretty_print(printer); end
  end
end
