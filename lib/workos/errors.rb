# frozen_string_literal: true

module WorkOS
  class WorkOSError < StandardError
    attr_reader :http_status
    attr_reader :request_id

    # Initializes a WorkOSError.
    def initialize(message = nil, http_status: nil, request_id: nil)
      @message = message
      @http_status = http_status
      @request_id = request_id
    end

    def to_s
      status_string = @http_status.nil? ? '' : "Status #{@http_status}, "
      id_string = @request_id.nil? ? '' : " - request ID: #{@request_id}"
      "#{status_string}#{@message}#{id_string}"
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
end
