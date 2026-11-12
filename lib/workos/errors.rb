# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained runtime
module WorkOS
  # Base class for all SDK errors.
  class Error < StandardError
    attr_reader :http_status, :request_id, :code, :body

    def initialize(message:, http_status: nil, request_id: nil, code: nil, body: nil)
      super(message)
      @http_status = http_status
      @request_id = request_id
      @code = code
      @body = body
    end
  end

  class APIError < Error; end
  class APIConnectionError < Error; end
  class AuthenticationError < APIError; end
  class ForbiddenRequestError < APIError; end
  class IdempotencyError < APIError; end
  class InvalidRequestError < APIError; end
  class NotFoundError < APIError; end
  class RateLimitExceededError < APIError; end
  class UnprocessableEntityError < APIError; end
  class SignatureVerificationError < Error; end

  # Raised when workload identity federation cannot produce an access token:
  # the credentials are misconfigured, the identity token provider failed, or
  # the token endpoint rejected or could not complete the exchange.
  #
  # - `code` is the OAuth error code from the token endpoint, or one of the
  #   SDK codes `exchange_failed`, `invalid_response`, `provider_failed` and
  #   `invalid_configuration`.
  # - `description` is the server's `error_description` (or the SDK's own
  #   detail), cut to {DESCRIPTION_LIMIT} characters; empty when there is none.
  # - `hint` is one sentence saying what to check; never empty.
  #
  # Neither the identity token nor the access token appears in any of them.
  class WorkloadIdentityError < Error
    DESCRIPTION_LIMIT = 500

    # The one table of hint wording. Keys are error codes.
    HINTS = {
      "invalid_grant" => "The identity token did not match a trust rule for this application, or the token has expired. Check the issuer, audience and subject claims against the trust rule.",
      "invalid_target" => "The resource or audience is wrong. The trust rule's audience must match the audience the identity token was requested with, and the resource must be registered for the environment.",
      "invalid_client" => "Check that the client ID is the M2M application that has the trust rule.",
      "unauthorized_client" => "This application is not allowed to use workload identity federation. Check that the feature is enabled for the environment and that the application has a trust rule.",
      "invalid_scope" => "The requested scope is not allowed for this application. Fix the scope or leave it unset.",
      "invalid_request" => "The token request was malformed. Check that the token URL points at the `/oauth2/token` endpoint.",
      "exchange_failed" => "The token endpoint could not be reached or kept failing. Check the token URL and try again.",
      "invalid_response" => "The token endpoint returned a response the SDK could not read. Check that the token URL points at the `/oauth2/token` endpoint.",
      "provider_failed" => "The identity token provider failed, so there was no token to exchange.",
      "invalid_configuration" => "Workload identity credentials are missing a required setting."
    }.freeze

    # The hint for an OAuth code the table does not list.
    DEFAULT_HINT = "The token endpoint rejected the exchange."

    attr_reader :description, :hint

    def initialize(code:, description: nil)
      code = code.to_s
      @description = description.to_s[0, DESCRIPTION_LIMIT]
      @hint = HINTS.fetch(code, DEFAULT_HINT)
      message = "#{code}: #{@hint}"
      message = "#{message} #{@description}" unless @description.empty?
      super(message: message, code: code)
    end
  end
end
