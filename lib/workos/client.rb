# frozen_string_literal: true
# typed: false

module WorkOS
  # A Net::HTTP based API client for interacting with the WorkOS API
  module Client
    extend T::Sig
    include Kernel

    sig { returns(Net::HTTP) }
    def client
      Net::HTTP.new(WorkOS::API_HOSTNAME, 443).tap do |http_client|
        http_client.use_ssl = true
        http_client.open_timeout = WorkOS.config.timeout
        http_client.read_timeout = WorkOS.config.timeout
        http_client.write_timeout = WorkOS.config.timeout
      end
    end

    sig do
      params(
        request: T.any(Net::HTTP::Get, Net::HTTP::Post, Net::HTTP::Delete, Net::HTTP::Put),
      ).returns(::T.untyped)
    end
    def execute_request(request:)
      begin
        response = client.request(request)
      rescue Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout
        raise TimeoutError.new(
          message: 'API Timeout Error',
        )
      end

      http_status = response.code.to_i
      handle_error_response(response: response) if http_status >= 400

      response
    end

    sig do
      params(
        path: String,
        auth: T.nilable(T::Boolean),
        params: T.nilable(Hash),
        access_token: T.nilable(String),
      ).returns(Net::HTTP::Get)
    end
    def get_request(path:, auth: false, params: {}, access_token: nil)
      uri = URI(path)
      uri.query = URI.encode_www_form(params) if params

      request = Net::HTTP::Get.new(
        uri.to_s,
        'Content-Type' => 'application/json',
      )

      request['Authorization'] = "Bearer #{access_token || WorkOS.config.key!}" if auth
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
      request['Authorization'] = "Bearer #{WorkOS.config.key!}" if auth
      request['Idempotency-Key'] = idempotency_key if idempotency_key
      request['User-Agent'] = user_agent
      request
    end

    sig do
      params(
        path: String,
        auth: T.nilable(T::Boolean),
        params: T.nilable(Hash),
      ).returns(Net::HTTP::Delete)
    end
    def delete_request(path:, auth: false, params: {})
      uri = URI(path)
      uri.query = URI.encode_www_form(params) if params

      request = Net::HTTP::Delete.new(
        uri.to_s,
        'Content-Type' => 'application/json',
      )

      request['Authorization'] = "Bearer #{WorkOS.config.key!}" if auth
      request['User-Agent'] = user_agent
      request
    end

    sig do
      params(
        path: String,
        auth: T.nilable(T::Boolean),
        idempotency_key: T.nilable(String),
        body: T.nilable(Hash),
      ).returns(Net::HTTP::Put)
    end
    def put_request(path:, auth: false, idempotency_key: nil, body: nil)
      request = Net::HTTP::Put.new(path, 'Content-Type' => 'application/json')
      request.body = body.to_json if body
      request['Authorization'] = "Bearer #{WorkOS.config.key!}" if auth
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
      when 404
        raise APIError.new(
          message: json['message'],
          http_status: http_status,
          request_id: response['x-request-id'],
        )
      when 422
        message = json['message']
        code = json['code']
        errors = extract_error(json['errors']) if json['errors']
        message += " (#{errors})" if errors

        raise InvalidRequestError.new(
          message: message,
          http_status: http_status,
          request_id: response['x-request-id'],
          code: code,
        )
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    private

    def extract_error(errors)
      errors.map do |error|
        "#{error['field']}: #{error['code']}"
      end.join('; ')
    end
  end
end
