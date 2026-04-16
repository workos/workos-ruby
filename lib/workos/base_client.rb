# @oagen-ignore-file — hand-maintained runtime
require "json"
require "net/http"
require "securerandom"
require "uri"
require "workos/errors"

module WorkOS
  # Instance-scoped HTTP runtime that implements request execution,
  # retry policy with exponential backoff + jitter, error translation,
  # and per-request option overrides.
  class BaseClient
    DEFAULT_BASE_URL = "https://api.workos.com"
    DEFAULT_TIMEOUT = 30
    DEFAULT_MAX_RETRIES = 2
    RETRYABLE_STATUSES = [408, 409, 429, 500, 502, 503, 504].freeze
    RETRY_BACKOFF_BASE = 0.5

    attr_reader :api_key, :base_url, :client_id, :timeout, :max_retries, :user_agent

    def initialize(api_key: nil, base_url: DEFAULT_BASE_URL, client_id: nil,
      timeout: DEFAULT_TIMEOUT, max_retries: DEFAULT_MAX_RETRIES,
      user_agent: "workos-ruby/0.0.0")
      @api_key = api_key
      @base_url = base_url
      @client_id = client_id
      @timeout = timeout
      @max_retries = max_retries
      @user_agent = user_agent
    end

    # -- Request builders -------------------------------------------------

    def get_request(path:, auth: false, params: {}, request_options: nil)
      build_request(Net::HTTP::Get, append_query(path, params),
        auth: auth, request_options: request_options)
    end

    def post_request(path:, auth: false, body: {}, params: {}, request_options: nil)
      req = build_request(Net::HTTP::Post, append_query(path, params),
        auth: auth, request_options: request_options)
      req.body = body.nil? ? "" : body.compact.to_json
      req["Content-Type"] = "application/json"
      inject_idempotency_key(req, request_options)
      req
    end

    def put_request(path:, auth: false, body: {}, params: {}, request_options: nil)
      req = build_request(Net::HTTP::Put, append_query(path, params),
        auth: auth, request_options: request_options)
      req.body = body.nil? ? "" : body.compact.to_json
      req["Content-Type"] = "application/json"
      inject_idempotency_key(req, request_options)
      req
    end

    def patch_request(path:, auth: false, body: {}, params: {}, request_options: nil)
      req = build_request(Net::HTTP::Patch, append_query(path, params),
        auth: auth, request_options: request_options)
      req.body = body.nil? ? "" : body.compact.to_json
      req["Content-Type"] = "application/json"
      inject_idempotency_key(req, request_options)
      req
    end

    def delete_request(path:, auth: false, body: nil, params: {}, request_options: nil)
      req = build_request(Net::HTTP::Delete, append_query(path, params),
        auth: auth, request_options: request_options)
      if body
        req.body = body.compact.to_json
        req["Content-Type"] = "application/json"
      end
      req
    end

    # -- Execution --------------------------------------------------------

    def execute_request(request:, request_options: nil)
      opts = request_options || {}
      base = opts[:base_url] || @base_url
      timeout = opts[:timeout] || @timeout
      retries = opts[:max_retries] || @max_retries
      attempt = 0

      loop do
        http = connection_for(base, timeout)
        response = http.request(request)
        return response if response.is_a?(Net::HTTPSuccess)

        if attempt < retries && retryable?(response)
          attempt += 1
          sleep(retry_delay(response, attempt))
          next
        end
        handle_error_response(response)
      rescue Net::OpenTimeout, Net::ReadTimeout,
        Errno::ECONNRESET, Errno::ECONNREFUSED,
        IOError, Errno::EPIPE => e
        evict_connection(base)
        if attempt < retries
          attempt += 1
          sleep(retry_delay(nil, attempt))
          next
        end
        raise WorkOS::APIConnectionError.new(message: e.message)
      end
    end

    # Close all persistent connections.
    def shutdown
      @connections&.each_value { |c| c.finish if c.started? }
      @connections = {}
    end

    private

    def append_query(path, params)
      return path unless params.is_a?(Hash) && !params.empty?

      query = URI.encode_www_form(params.compact)
      return path if query.empty?

      path.include?("?") ? "#{path}&#{query}" : "#{path}?#{query}"
    end

    def connection_for(base_url, timeout)
      uri = URI(base_url)
      key = "#{uri.host}:#{uri.port}"

      @connections ||= {}
      conn = @connections[key]

      if conn&.started?
        conn.read_timeout = timeout
        conn.open_timeout = timeout
        return conn
      end

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.read_timeout = timeout
      http.open_timeout = timeout
      http.keep_alive_timeout = 30
      http.start
      @connections[key] = http
      http
    end

    def evict_connection(base_url)
      uri = URI(base_url)
      key = "#{uri.host}:#{uri.port}"
      conn = @connections&.delete(key)
      conn&.finish if conn&.started?
    rescue IOError
      # Already closed, ignore
    end

    def resolve_option(opts, key)
      return nil unless opts.is_a?(Hash)
      opts[key] || opts[key.to_s]
    end

    def build_request(klass, path, auth:, request_options:)
      request = klass.new(path)
      if auth
        key = resolve_option(request_options, :api_key) || @api_key
        request["Authorization"] = "Bearer #{key}" if key && !key.empty?
      end
      request["User-Agent"] = @user_agent
      apply_extra_headers(request, request_options)
      request
    end

    def apply_extra_headers(request, request_options)
      return unless request_options.is_a?(Hash)

      extra = request_options[:extra_headers] || request_options["extra_headers"]
      return unless extra.is_a?(Hash)

      extra.each { |k, v| request[k.to_s] = v.to_s }
    end

    def inject_idempotency_key(request, request_options)
      key = nil
      if request_options.is_a?(Hash)
        key = request_options[:idempotency_key] || request_options["idempotency_key"]
      end
      key ||= SecureRandom.uuid
      request["Idempotency-Key"] ||= key
    end

    def retryable?(response)
      RETRYABLE_STATUSES.include?(response.code.to_i)
    end

    def retry_delay(response, attempt)
      if response
        retry_after = response["Retry-After"]
        return retry_after.to_f if retry_after&.to_f&.positive?
      end

      base = RETRY_BACKOFF_BASE * (2**(attempt - 1))
      jitter = rand * 0.25 * base
      base + jitter
    end

    def handle_error_response(response)
      status = response.code.to_i
      body = begin
        JSON.parse(response.body.to_s)
      rescue
        {}
      end
      request_id = response["x-request-id"] || response["X-Request-Id"]
      error_args = {
        message: body["message"] || "HTTP #{status}",
        http_status: status,
        request_id: request_id,
        code: body["code"],
        body: body
      }

      case status
      when 400 then raise WorkOS::InvalidRequestError.new(**error_args)
      when 401 then raise WorkOS::AuthenticationError.new(**error_args)
      when 403 then raise WorkOS::ForbiddenRequestError.new(**error_args)
      when 404 then raise WorkOS::NotFoundError.new(**error_args)
      when 422 then raise WorkOS::UnprocessableEntityError.new(**error_args)
      when 429 then raise WorkOS::RateLimitExceededError.new(**error_args)
      else raise WorkOS::APIError.new(**error_args)
      end
    end
  end
end
