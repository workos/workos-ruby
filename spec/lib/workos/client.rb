# frozen_string_literal: true

describe WorkOS::Client do
  let(:client) { Class.new { extend WorkOS::Client } }

  describe '#handle_error_response' do
    context 'when the status is 400' do
      let(:response) { OpenStruct.new(code: '400', 'x-request-id': 'req_123', body: '{"code": "invalid_request", "error": "invalid request made", "error_description": "Invalid request", "ids": ["foo", "bar"]}', message: 'Bad Request') }

      it 'raises an InvalidRequestError with correct attributes' do
        begin
          client.handle_error_response(response: response)
        rescue WorkOS::InvalidRequestError => error
          expect(error.message).to eq('Status 400, error: invalid request made, error_description: Invalid request ids: ["foo", "bar"] - request ID: req_123')
        end
      end
    end

    context 'when the status is 401' do
      let(:response) { OpenStruct.new(code: '401', 'x-request-id': 'req_123', body: '{}', message: 'Unauthorized') }

      it 'raises an AuthenticationError with correct attributes' do
        begin
          client.handle_error_response(response: response)
        rescue WorkOS::AuthenticationError => error
          expect(error.message).to eq('Status 401, Unauthorized - request ID: req_123')
        end
      end
    end

    context 'when the status is 404' do
      let(:response) { OpenStruct.new(code: '404', 'x-request-id': 'req_123', body: '{"code": "not_found", "message": "Resource not found"}', message: 'Not Found') }

      it 'raises a NotFoundError with correct attributes' do
        begin
          client.handle_error_response(response: response)
        rescue WorkOS::NotFoundError => error
          expect(error.message).to eq('Status 404, Resource not found - request ID: req_123')
        end
      end
    end

    context 'when the status is 422' do
      let(:response) { OpenStruct.new(code: '422', 'x-request-id': 'req_123', body: '{"code": "unprocessable_entity", "error": "Unprocessable entity", "message": "Unprocessable request"}', message: 'Unprocessable Entity') }

      it 'raises an UnprocessableEntityError with correct attributes' do
        begin
          client.handle_error_response(response: response)
        rescue WorkOS::UnprocessableEntityError => error
          expect(error.message).to eq('Status 422, error: Unprocessable entity, error_description: Unprocessable request - request ID: req_123')
        end
      end
    end

    context 'when the status is 429' do
      let(:response) { OpenStruct.new(
        code: '429',
        'x-request-id': 'req_123',
        'Retry-After': 'tomorrow',
        message: 'Too Many Requests'
      ) }

      it 'raises a RateLimitExceededError with correct attributes' do
        begin
          client.handle_error_response(response: response)
        rescue WorkOS::RateLimitExceededError => error
          expect(error.message).to eq('Status 429, Too Many Requests Retry-After: tomorrow - request ID: req_123')
        end
      end
    end

    context 'when the status is not recognized' do
      let(:response) { OpenStruct.new(code: '500', 'x-request-id': 'req_123', body: '{"code": "internal_server_error", "error": "Internal server error", "error_description": "Unexpected error"}', message: 'Internal Server Error') }

      it 'raises a WorkOSError with correct attributes' do
        begin
          client.handle_error_response(response: response)
        rescue WorkOS::APIError => error
          expect(error.message).to eq('Status 500, error: Internal server error, error_description: Unexpected error  - request ID: req_123')
        end
      end
    end
  end
end