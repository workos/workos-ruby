# frozen_string_literal: true

module WorkOS
  # A Net::HTTP based API client for interacting with the WorkOS API
  module Client
    include Kernel

    def client
      Net::HTTP.new(WorkOS.config.api_hostname, 443).tap do |http_client|
        http_client.use_ssl = true
        http_client.open_timeout = WorkOS.config.timeout
        http_client.read_timeout = WorkOS.config.timeout
        http_client.write_timeout = WorkOS.config.timeout if RUBY_VERSION >= '2.6.0'
      end
    end

    # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    def execute_request(request:, retries: nil)
      retries = retries.nil? ? WorkOS.config.max_retries : retries
      attempt = 0

      begin
        response = client.request(request)
        http_status = response.code.to_i

        if http_status >= 400
          if retryable_error?(http_status) && attempt < retries
            attempt += 1
            delay = calculate_retry_delay(attempt, response)
            sleep(delay)
            raise RetryableError.new(http_status: http_status)
          else
            handle_error_response(response: response)
          end
        end

        response
      rescue Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout
        if attempt < retries
          attempt += 1
          delay = calculate_backoff(attempt)
          sleep(delay)
          retry
        else
          raise TimeoutError.new(
            message: 'API Timeout Error',
          )
        end
      rescue RetryableError
        retry
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity

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

    def post_request(path:, auth: false, idempotency_key: nil, body: nil)
      request = Net::HTTP::Post.new(path, 'Content-Type' => 'application/json')
      request.body = body.to_json if body
      request['Authorization'] = "Bearer #{WorkOS.config.key!}" if auth
      request['Idempotency-Key'] = idempotency_key if idempotency_key
      request['User-Agent'] = user_agent
      request
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

    def put_request(path:, auth: false, idempotency_key: nil, body: nil)
      request = Net::HTTP::Put.new(path, 'Content-Type' => 'application/json')
      request.body = body.to_json if body
      request['Authorization'] = "Bearer #{WorkOS.config.key!}" if auth
      request['Idempotency-Key'] = idempotency_key if idempotency_key
      request['User-Agent'] = user_agent
      request
    end

    def user_agent
      engine = defined?(::RUBY_ENGINE) ? ::RUBY_ENGINE : 'Ruby'

      [
        'WorkOS',
        "#{engine}/#{RUBY_VERSION}",
        RUBY_PLATFORM,
        "v#{WorkOS::VERSION}"
      ].join('; ')
    end

    # rubocop:disable Metrics/AbcSize:
    def handle_error_response(response:)
      http_status = response.code.to_i
      json = JSON.parse(response.body)

      case http_status
      when 400
        raise InvalidRequestError.new(
          message: json['message'],
          http_status: http_status,
          request_id: response['x-request-id'],
          code: json['code'],
          errors: json['errors'],
          error: json['error'],
          error_description: json['error_description'],
          data: json,
        )
      when 401
        raise AuthenticationError.new(
          message: json['message'],
          http_status: http_status,
          request_id: response['x-request-id'],
        )
      when 403
        raise ForbiddenRequestError.new(
          message: json['message'],
          http_status: http_status,
          request_id: response['x-request-id'],
          code: json['code'],
          data: json,
        )
      when 404
        raise NotFoundError.new(
          message: json['message'],
          http_status: http_status,
          request_id: response['x-request-id'],
        )
      when 422
        message = json['message']
        code = json['code']
        errors = extract_error(json['errors']) if json['errors']
        message += " (#{errors})" if errors

        raise UnprocessableEntityError.new(
          message: message,
          http_status: http_status,
          request_id: response['x-request-id'],
          error: json['error'],
          errors: errors,
          code: code,
        )
      when 429
        raise RateLimitExceededError.new(
          message: json['message'],
          http_status: http_status,
          request_id: response['x-request-id'],
          retry_after: response['Retry-After'],
        )
      else
        raise APIError.new(
          message: json['message'],
          http_status: http_status,
          request_id: response['x-request-id'],
        )
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity:

    private

    def retryable_error?(http_status)
      http_status >= 500 || http_status == 429
    end

    def calculate_backoff(attempt)
      base_delay = 1.0
      max_delay = 30.0
      jitter_percentage = 0.25

      delay = [base_delay * (2**(attempt - 1)), max_delay].min
      jitter = delay * jitter_percentage * rand
      delay + jitter
    end

    def calculate_retry_delay(attempt, response)
      # If it's a 429 with Retry-After header, use that
      if response.code.to_i == 429 && response['Retry-After']
        retry_after = response['Retry-After'].to_i
        return retry_after if retry_after.positive?
      end

      # Otherwise use exponential backoff
      calculate_backoff(attempt)
    end

    def extract_error(errors)
      errors.map do |error|
        "#{error['field']}: #{error['code']}"
      end.join('; ')
    end
  end
end
