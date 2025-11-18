# frozen_string_literal: true

module WorkOS
  # Parent class for WorkOS related errors
  class WorkOSError < StandardError
    attr_reader :http_status
    attr_reader :request_id
    attr_reader :code
    attr_reader :errors
    attr_reader :error
    attr_reader :error_description
    attr_reader :data
    attr_reader :retry_after

    # rubocop:disable Metrics/ParameterLists
    def initialize(
      message: nil,
      error: nil,
      error_description: nil,
      http_status: nil,
      request_id: nil,
      code: nil,
      errors: nil,
      data: nil,
      retry_after: nil
    )
      @message = message
      @error = error
      @error_description = error_description
      @http_status = http_status
      @request_id = request_id
      @code = code
      @errors = errors
      @data = data
      @retry_after = retry_after
    end
    # rubocop:enable Metrics/ParameterLists

    def to_s
      status_string = @http_status.nil? ? '' : "Status #{@http_status}, "
      id_string = @request_id.nil? ? '' : " - request ID: #{@request_id}"
      if @error && @error_description
        error_string = "error: #{@error}, error_description: #{@error_description}"
        "#{status_string}#{error_string}#{id_string}"
      elsif @error
        "#{status_string}#{@error}#{id_string}"
      else
        "#{status_string}#{@message}#{id_string}"
      end
    end

    def retryable?
      return true if http_status && (http_status >= 500 || http_status == 429)

      false
    end
  end

  # APIError is a generic error that may be raised in cases where none of the
  # other named errors cover the problem. It could also be raised in the case
  # that a new error has been introduced in the API, but this version of the
  # Ruby SDK doesn't know how to handle it.
  class APIError < WorkOSError; end

  # AuthenticationError is raised when invalid credentials are used to connect
  # to WorkOS's servers.
  class AuthenticationError < WorkOSError; end

  # InvalidRequestError is raised when a request is initiated with invalid
  # parameters.
  class InvalidRequestError < WorkOSError; end

  # ForbiddenError is raised when a request is forbidden, likely due to missing a step
  # (i.e. verifying email ownership before authenticating).
  class ForbiddenRequestError < WorkOSError; end

  # SignatureVerificationError is raised when the signature verification for a
  # webhook fails
  class SignatureVerificationError < WorkOSError; end

  # TimeoutError is raised when the HTTP request to the API times out
  class TimeoutError < WorkOSError; end

  # RateLimitExceededError is raised when the rate limit for the API has been hit
  class RateLimitExceededError < WorkOSError; end

  # NotFoundError is raised when a resource is not found
  class NotFoundError < WorkOSError; end

  # UnprocessableEntityError is raised when a request is made that cannot be processed
  class UnprocessableEntityError < WorkOSError; end
end
