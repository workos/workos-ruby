# frozen_string_literal: true
# typed: true


module WorkOS
  # Parent class for WorkOS related errors
  class WorkOSError < StandardError
    extend T::Sig

    attr_reader :http_status
    attr_reader :request_id
    attr_reader :code
    attr_reader :errors

    # rubocop:disable Metrics/ParameterLists
    sig do
      params(
        message: T.nilable(String),
        error: T.nilable(String),
        error_description: T.nilable(String),
        http_status: T.nilable(Integer),
        request_id: T.nilable(String),
        code: T.nilable(String),
        errors: T.nilable(T::Array[T::Hash[T.untyped, T.untyped]]),
      ).void
    end
    def initialize(
      message: nil,
      error: nil,
      error_description: nil,
      http_status: nil,
      request_id: nil,
      code: nil,
      errors: nil
    )
      @message = message
      @error = error
      @error_description = error_description
      @http_status = http_status
      @request_id = request_id
      @code = code
      @errors = errors
    end
    # rubocop:enable Metrics/ParameterLists

    sig { returns(String) }
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

  # SignatureVerificationError is raised when the signature verification for a
  # webhook fails
  class SignatureVerificationError < WorkOSError; end

  # TimeoutError is raised when the HTTP request to the API times out
  class TimeoutError < WorkOSError; end
end
