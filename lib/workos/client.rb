# frozen_string_literal: true
# typed: true

# rubocop:disable Style/Documentation
module WorkOS
  module Client
    extend T::Sig

    sig { returns(Net::HTTP) }
    def client
      return @client if defined?(@client)

      @client = Net::HTTP.new(WorkOS::API_HOSTNAME, 443)
      @client.use_ssl = true

      @client
    end

    sig { params(request: Net::HTTP::Post).returns(::T.untyped) }
    def execute_request(request:)
      response = client.request(request)

      http_status = response.code.to_i
      handle_error_response(response: response) if http_status >= 400

      response
    end

    sig { params(path: String, body: Hash).returns(Net::HTTP::Post) }
    def post_request(path:, body: nil)
      request = Net::HTTP::Post.new(path, 'Content-Type' => 'application/json')
      request.body = body.to_json if body
      request['User-Agent'] = user_agent
      request
    end

    sig { returns(String) }
    def user_agent
      engine = defined?(::RUBY_ENGINE) ? ::RUBY_ENGINE : 'Ruby'

      [
        'WorkOS',
        "#{engine}/#{RUBY_VERSION}",
        RUBY_PLATFORM,
        "v#{WorkOS::VERSION}"
      ].join('; ')
    end


    sig { params(response: ::T.untyped).void }
    def handle_error_response(response:)
      http_status = response.code.to_i
      json = JSON.parse(response.body)

      options = {
        http_status: http_status,
        request_id: response['x-request-id'],
      }

      case http_status
      when 400
        raise InvalidRequestError.new(json['message'], **options)
      when 401
        message = 'Unauthorized (check your API key)'
        raise AuthenticationError.new(json['message'], **options)
      when 422
        errors = json['errors'].map { |error| "#{error['field']}: #{error['code']}" }.join('; ')
        message = "#{json['message']} (#{errors})"
        raise InvalidRequestError.new(message, **options)
      end
    end
  end
end
