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
      retry_after_string = @retry_after.nil? ? '' : " Retry-After: #{@retry_after}"
      id_string = @request_id.nil? ? '' : " - request ID: #{@request_id}"

      if @error && @error_description && @data
        error_string = "error: #{@error}, error_description: #{@error_description} #{extract_fields(@data)}"
        "#{status_string}#{error_string}#{retry_after_string}#{id_string}"
      elsif @error && @error_description
        error_string = "error: #{@error}, error_description: #{@error_description}"
        "#{status_string}#{error_string}#{retry_after_string}#{id_string}"
      elsif @error
        "#{status_string}#{@error}#{retry_after_string}#{id_string}"
      else
        "#{status_string}#{@message}#{retry_after_string}#{id_string}"
      end
    end

    def extract_fields(data)
      # return early if data is empty or nil
      return '' if data.nil? || data.empty?

      ret = []

      # loop over data and return key value pairs
      data.each_pair do |field, value|
        if field.to_s != "error" && field.to_s != "error_description" && field.to_s != "code"
          ret.push("#{field}: #{value}")
        end
      end

      ret.join(', ')
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

  # RateLimitExceededError is raised when the rate limit for the API has been hit
  class RateLimitExceededError < WorkOSError; end

  # NotFoundError is raised when a resource is not found
  class NotFoundError < WorkOSError; end

  # UnprocessableEntityError is raised when a request is made that cannot be processed
  class UnprocessableEntityError < WorkOSError; end
end
