# frozen_string_literal: true
# typed: true

module WorkOS
  # A Net::HTTP based API client for interacting with the WorkOS API
  module Client
    extend T::Sig
    include Kernel

    sig { returns(Net::HTTP) }
    def client
      return @client if defined?(@client)

      @client = Net::HTTP.new(WorkOS::API_HOSTNAME, 443)
      @client.use_ssl = true

      @client
    end

    sig do
      params(
        request: T.any(Net::HTTP::Get, Net::HTTP::Post),
      ).returns(::T.untyped)
    end
    def execute_request(request:)
      response = client.request(request)

      http_status = response.code.to_i
      handle_error_response(response: response) if http_status >= 400

      response
    end

    sig do
      params(
        path: String,
        auth: T.nilable(T::Boolean),
        params: T.nilable(Hash),
      ).returns(Net::HTTP::Get)
    end
    def get_request(path:, auth: false, params: {})
      uri = URI(path)
      uri.query = URI.encode_www_form(params) if params

      request = Net::HTTP::Get.new(
        uri.to_s,
        'Content-Type' => 'application/json',
      )

      request['Authorization'] = "Bearer #{WorkOS.key!}" if auth
      request['User-Agent'] = user_agent
      request
    end

    sig do
      params(
        path: String,
        auth: T.nilable(T::Boolean),
        idempotency_key: T.nilable(String),
        body: T.nilable(Hash),
      ).returns(Net::HTTP::Post)
    end
    def post_request(path:, auth: false, idempotency_key: nil, body: nil)
      request = Net::HTTP::Post.new(path, 'Content-Type' => 'application/json')
      request.body = body.to_json if body
      request['Authorization'] = "Bearer #{WorkOS.key!}" if auth
      request['Idempotency-Key'] = idempotency_key if idempotency_key
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


    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    sig { params(response: ::T.untyped).void }
    def handle_error_response(response:)
      http_status = response.code.to_i
      json = JSON.parse(response.body)

      case http_status
      when 400
        raise InvalidRequestError.new(
          message: json['message'],
          http_status: http_status,
          request_id: response['x-request-id'],
        )
      when 401
        raise AuthenticationError.new(
          message: json['message'],
          http_status: http_status,
          request_id: response['x-request-id'],
        )
      when 422
        errors = json['errors'].map do |error|
          "#{error['field']}: #{error['code']}"
        end.join('; ')

        message = "#{json['message']} (#{errors})"
        raise InvalidRequestError.new(
          message: message,
          http_status: http_status,
          request_id: response['x-request-id'],
        )
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  end
end
