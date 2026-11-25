# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained runtime
module WorkOS
  # What a credentials object hands the HTTP runtime for one HTTP attempt.
  #
  # Credentials are a duck type with two methods:
  #
  # - `resolve(timeout:)` returns a CredentialSnapshot. It may block (a
  #   workload identity exchange) for at most `timeout` seconds.
  # - `invalidate(generation)` marks that generation as no longer usable. It
  #   never touches the network.
  #
  # `headers` are set on the request, replacing any `Authorization` header
  # already there. `generation` identifies the credential the headers came
  # from, so a 401 invalidates the credential that was actually sent.
  # `recoverable` is true when a 401 is worth one re-resolve and resend.
  CredentialSnapshot = Data.define(:headers, :generation, :recoverable) do
    # The headers carry a bearer token; keep it out of logs and error output.
    def inspect
      "#<data WorkOS::CredentialSnapshot generation=#{generation.inspect} recoverable=#{recoverable.inspect} headers=[REDACTED]>"
    end
    alias_method :to_s, :inspect

    # `pp` prints a Data object member by member unless told otherwise.
    def pretty_print(printer)
      printer.text(inspect)
    end
  end
end
