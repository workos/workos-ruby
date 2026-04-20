# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained runtime
require "json"
require "logger"
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
    MAX_CACHED_CONNECTIONS = 8
    RETRY_BACKOFF_BASE = 0.5
    LOG_SEVERITY = {debug: 0, info: 1, warn: 2, error: 3, unknown: 4}.freeze

    USER_AGENT = "workos-ruby/#{WorkOS::VERSION} ruby/#{RUBY_VERSION} (#{RUBY_PLATFORM})"

    attr_reader :api_key, :base_url, :client_id, :timeout, :max_retries, :logger, :log_level

    def initialize(api_key: nil, base_url: DEFAULT_BASE_URL, client_id: nil,
      timeout: DEFAULT_TIMEOUT, max_retries: DEFAULT_MAX_RETRIES,
      logger: nil, log_level: nil, random: Random.new)
      @api_key = api_key
      @base_url = base_url
      @client_id = client_id
      @timeout = timeout
      @max_retries = max_retries
      @logger = logger
      @log_level = log_level
      @random = random
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

    # -- Convenience entry point ------------------------------------------

    # Unified request helper: builds the verb-specific request and executes
    # it in a single call, removing the need for callers to pass
    # request_options twice.
    def request(method:, path:, auth: true, params: {}, body: nil, request_options: {})
      raise ArgumentError, "unsupported method" unless %i[get post put patch delete].include?(method)

      req = case method
      when :get
        get_request(path: path, auth: auth, params: params, request_options: request_options)
      when :post
        post_request(path: path, auth: auth, body: body, params: params, request_options: request_options)
      when :put
        put_request(path: path, auth: auth, body: body, params: params, request_options: request_options)
      when :patch
        patch_request(path: path, auth: auth, body: body, params: params, request_options: request_options)
      when :delete
        delete_request(path: path, auth: auth, body: body, params: params, request_options: request_options)
      end
      execute_request(request: req, request_options: request_options)
    end

    # -- Execution --------------------------------------------------------

    def execute_request(request:, request_options: nil)
      opts = (request_options || {}).transform_keys(&:to_sym)
      base = opts[:base_url] || @base_url
      timeout = opts[:timeout] || @timeout
      retries = opts[:max_retries] || @max_retries
      attempt = 0

      loop do
        log(:debug, "request start", method: request.method, path: request.path, attempt: attempt + 1)
        http = connection_for(base, timeout)
        response = http.request(request)
        return response if response.is_a?(Net::HTTPSuccess)

        if attempt < retries && retryable?(response)
          attempt += 1
          inject_retry_idempotency_key(request)
          log(:info, "request retry", method: request.method, path: request.path, attempt: attempt + 1, status: response.code.to_i)
          sleep(retry_delay(response, attempt))
          next
        end
        log(:warn, "request error", method: request.method, path: request.path, status: response.code.to_i, request_id: response["x-request-id"] || response["X-Request-Id"])
        handle_error_response(response)
      rescue Net::OpenTimeout, Net::ReadTimeout,
        Errno::ECONNRESET, Errno::ECONNREFUSED,
        IOError, Errno::EPIPE => e
        evict_connection(base)
        if attempt < retries
          attempt += 1
          inject_retry_idempotency_key(request)
          log(:info, "request retry", method: request.method, path: request.path, attempt: attempt + 1, error: e.class.name)
          sleep(retry_delay(nil, attempt))
          next
        end
        log(:warn, "connection error", method: request.method, path: request.path, error: e.class.name, message: e.message)
        raise WorkOS::APIConnectionError.new(message: e.message)
      end
    end

    # Close all persistent connections cached by this client on the current
    # fiber/thread.
    #
    # Call this before forking (e.g. in a Puma `on_worker_boot` block) to
    # avoid sharing `Net::HTTP` sockets across processes.
    #
    # @return [void]
    def shutdown
      connections = thread_connections.values
      thread_connections.clear
      connections.each { |connection| connection.finish if connection.started? }
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
      key = connection_key(uri, timeout)
      conn = thread_connections[key]

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
      cache = thread_connections
      cache[key] = http
      evict_lru_connections(cache) if cache.size > MAX_CACHED_CONNECTIONS
      http
    end

    def evict_connection(base_url)
      uri = URI(base_url)
      keys = thread_connections.keys.select { |key| key.start_with?("#{uri.scheme}:#{uri.host}:#{uri.port}:") }
      keys.each do |key|
        connection = thread_connections.delete(key)
        connection&.finish if connection&.started?
      end
    rescue IOError
      # Already closed, ignore
    end

    def evict_lru_connections(cache)
      while cache.size > MAX_CACHED_CONNECTIONS
        oldest_key = cache.keys.first
        conn = cache.delete(oldest_key)
        conn&.finish if conn&.started?
      end
    rescue IOError
      # Already closed, ignore
    end

    def connection_key(uri, timeout)
      "#{uri.scheme}:#{uri.host}:#{uri.port}:#{timeout}"
    end

    def thread_connections
      Fiber[:workos_connections] ||= {}
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
      request["User-Agent"] = USER_AGENT
      # Apply user headers before idempotency injection so caller-supplied
      # Idempotency-Key values win.
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
      key = resolve_option(request_options, :idempotency_key)
      return if key.nil? || key.to_s.empty?

      request["Idempotency-Key"] ||= key
    end

    def inject_retry_idempotency_key(request)
      return unless %w[POST PUT PATCH].include?(request.method)
      return if request["Idempotency-Key"]

      request["Idempotency-Key"] = SecureRandom.uuid
    end

    def log(level, message, details = {})
      sink = @logger
      return unless sink
      return unless loggable?(level)

      formatter = details.compact.map { |key, value| "#{key}=#{value}" }.join(" ")
      line = formatter.empty? ? message : "#{message} #{formatter}"
      if sink.respond_to?(level)
        sink.public_send(level, line)
      elsif sink.respond_to?(:add)
        sink.add(log_level_to_severity(level), line)
      end
    end

    def loggable?(level)
      LOG_SEVERITY.fetch(level, LOG_SEVERITY[:unknown]) >= LOG_SEVERITY.fetch(@log_level || :debug, LOG_SEVERITY[:debug])
    end

    def log_level_to_severity(level)
      case level
      when :debug then ::Logger::DEBUG
      when :info then ::Logger::INFO
      when :warn then ::Logger::WARN
      when :error then ::Logger::ERROR
      else ::Logger::UNKNOWN
      end
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
      jitter = @random.rand * 0.25 * base
      base + jitter
    end

    def handle_error_response(response)
      status = response.code.to_i
      body = begin
        JSON.parse(response.body.to_s)
      rescue JSON::ParserError
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
      when 409
        raise WorkOS::IdempotencyError.new(**error_args) if body["code"] == "idempotency_error"

        raise WorkOS::APIError.new(**error_args)
      when 422 then raise WorkOS::UnprocessableEntityError.new(**error_args)
      when 429 then raise WorkOS::RateLimitExceededError.new(**error_args)
      else raise WorkOS::APIError.new(**error_args)
      end
    end
  end
end
