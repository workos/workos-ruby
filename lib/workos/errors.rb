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
end
