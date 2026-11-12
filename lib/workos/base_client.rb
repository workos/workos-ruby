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
  #
  # @example Create a client with custom settings
  #   client = WorkOS::Client.new(
  #     api_key: "sk_...",
  #     client_id: "client_...",
  #     timeout: 60,
  #     max_retries: 3,
  #     logger: Logger.new($stdout),
  #     log_level: :info
  #   )
  #
  # @example Authenticate with workload identity in place of an API key
  #   client = WorkOS::Client.new(
  #     credentials: WorkOS::WorkloadIdentity::Credentials.new(
  #       identity_token_provider: WorkOS::WorkloadIdentity.token_file("/var/run/secrets/workos/token")
  #     )
  #   )
  #
  # @example Shut down connections before forking
  #   client.shutdown
  class BaseClient
    DEFAULT_BASE_URL = "https://api.workos.com"
    DEFAULT_TIMEOUT = 30
    DEFAULT_MAX_RETRIES = 2
    RETRYABLE_STATUSES = [408, 409, 429, 500, 502, 503, 504].freeze
    MAX_CACHED_CONNECTIONS = 8
    RETRY_BACKOFF_BASE = 0.5
    LOG_SEVERITY = {debug: 0, info: 1, warn: 2, error: 3, unknown: 4}.freeze

    USER_AGENT = [
      "WorkOS",
      "#{defined?(::RUBY_ENGINE) ? ::RUBY_ENGINE : "ruby"}/#{RUBY_VERSION}",
      RUBY_PLATFORM,
      "v#{WorkOS::VERSION}"
    ].join("; ").freeze

    # Marks a request built with `auth: true` and no per-request override, so
    # that execute_request resolves the client's credentials before each
    # attempt. Kept on the request because build and execute are two calls.
    CLIENT_CREDENTIALS = :@workos_client_credentials
    private_constant :CLIENT_CREDENTIALS

    attr_reader :api_key, :credentials, :base_url, :client_id, :timeout, :max_retries, :logger, :log_level, :jwt_issuer

    # Delay before retry number `attempt`: the server's `Retry-After` when it
    # sends a positive one, otherwise exponential backoff with jitter. The
    # workload identity token exchange calls this too, so both retry alike.
    #
    # @api private
    def self.retry_delay(response, attempt, random)
      if response
        retry_after = response["Retry-After"]
        return retry_after.to_f if retry_after&.to_f&.positive?
      end

      base = RETRY_BACKOFF_BASE * (2**(attempt - 1))
      jitter = random.rand * 0.25 * base
      base + jitter
    end

    # @param credentials [#resolve, #invalidate, nil] Credentials to
    #   authenticate with in place of an API key, such as
    #   {WorkOS::WorkloadIdentity::Credentials}. Passing both `api_key` and
    #   `credentials` is an error.
    # @param jwt_issuer [String, Array<String>, nil] Expected `iss` claim of
    #   session access tokens (one issuer or a list of accepted issuers).
    #   When nil, the issuer is not validated.
    def initialize(api_key: nil, credentials: nil, base_url: DEFAULT_BASE_URL, client_id: nil,
      timeout: DEFAULT_TIMEOUT, max_retries: DEFAULT_MAX_RETRIES,
      logger: nil, log_level: nil, jwt_issuer: nil, random: Random.new)
      if credentials
        if api_key && !api_key.empty?
          raise WorkOS::WorkloadIdentityError.new(
            code: "invalid_configuration",
            description: "api_key and credentials were both given; pass one or the other"
          )
        end
        unless credentials.respond_to?(:resolve) && credentials.respond_to?(:invalidate)
          raise ArgumentError, "credentials must respond to resolve and invalidate"
        end
      end
      @api_key = api_key
      @credentials = credentials || StaticKeyCredentials.new(api_key)
      @base_url = base_url
      @client_id = client_id
      @timeout = timeout
      @max_retries = max_retries
      @logger = logger
      @log_level = log_level
      @jwt_issuer = jwt_issuer
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
      req.body = body.nil? ? "" : body.to_json
      req["Content-Type"] = "application/json"
      inject_idempotency_key(req, request_options)
      # Keyed before the first attempt, so a retry after a lost response
      # carries the key the server already saw.
      req["Idempotency-Key"] ||= SecureRandom.uuid
      req
    end

    def put_request(path:, auth: false, body: {}, params: {}, request_options: nil)
      req = build_request(Net::HTTP::Put, append_query(path, params),
        auth: auth, request_options: request_options)
      req.body = body.nil? ? "" : body.to_json
      req["Content-Type"] = "application/json"
      inject_idempotency_key(req, request_options)
      req
    end

    def patch_request(path:, auth: false, body: {}, params: {}, request_options: nil)
      req = build_request(Net::HTTP::Patch, append_query(path, params),
        auth: auth, request_options: request_options)
      req.body = body.nil? ? "" : body.to_json
      req["Content-Type"] = "application/json"
      inject_idempotency_key(req, request_options)
      req
    end

    def delete_request(path:, auth: false, body: nil, params: {}, request_options: nil)
      req = build_request(Net::HTTP::Delete, append_query(path, params),
        auth: auth, request_options: request_options)
      if body
        req.body = body.to_json
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
      request_options = (request_options || {}).transform_keys(&:to_sym)

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
      # One credential recovery per logical request. It lives outside the
      # retry loop and is never cleared, so transport retries cannot earn a
      # second one. A streamed body cannot be sent twice, so such a request
      # has none; decided here, before the first send consumes the stream.
      recovery_used = !request.body_stream.nil?

      loop do
        loggable_path = redact_path(request.path)
        log(:debug, "request start", method: request.method, path: loggable_path, attempt: attempt + 1)
        # Resolved before every attempt, so a retry never sends an expired
        # token. The snapshot is kept: a 401 invalidates the credential this
        # attempt actually sent, not whichever is current by then.
        snapshot = authorize(request, timeout)
        response = transmit(request, base, timeout)
        if !recovery_used && recoverable_unauthorized?(response, snapshot)
          recovery_used = true
          log(:info, "credentials refresh", method: request.method, path: loggable_path, status: 401)
          @credentials.invalidate(snapshot.generation)
          authorize(request, timeout)
          # Same request object: same body bytes, same Idempotency-Key. Not
          # counted against the retry limit and not delayed by a backoff.
          response = transmit(request, base, timeout)
        end
        return response if response.is_a?(Net::HTTPSuccess)

        if attempt < retries && retryable?(response)
          attempt += 1
          inject_retry_idempotency_key(request)
          log(:info, "request retry", method: request.method, path: loggable_path, attempt: attempt + 1, status: response.code.to_i)
          sleep(retry_delay(response, attempt))
          next
        end
        log(:warn, "request error", method: request.method, path: loggable_path, status: response.code.to_i, request_id: response["x-request-id"] || response["X-Request-Id"])
        handle_error_response(response)
      rescue Net::OpenTimeout, Net::ReadTimeout,
        Errno::ECONNRESET, Errno::ECONNREFUSED,
        IOError, Errno::EPIPE => e
        evict_connection(base)
        if attempt < retries
          attempt += 1
          inject_retry_idempotency_key(request)
          log(:info, "request retry", method: request.method, path: loggable_path, attempt: attempt + 1, error: e.class.name)
          sleep(retry_delay(nil, attempt))
          next
        end
        log(:warn, "connection error", method: request.method, path: loggable_path, error: e.class.name, message: e.message)
        raise WorkOS::APIConnectionError.new(message: e.message)
      end
    end

    # Close all persistent connections cached by this client on the current
    # thread.
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

    # Redact path segments that carry bearer-equivalent tokens (e.g.
    # `/user_management/invitations/by_token/<token>`,
    # `/user_management/magic_auth/<token>`, password-reset / email-
    # verification token paths) before the path is written to a logger.
    # The WorkOS API exposes a small number of "by_token" endpoints whose
    # path segments are themselves authentication material; redacting them
    # here means the SDK never emits the token in its own log/retry/error
    # messages even when the host application configures verbose logging.
    REDACTED_TOKEN_PREFIXES = %w[
      /user_management/invitations/by_token
      /user_management/magic_auth
      /user_management/password_reset
      /user_management/email_verification
    ].freeze
    private_constant :REDACTED_TOKEN_PREFIXES

    # Query-string keys whose values are bearer-equivalent or otherwise
    # sensitive and should never appear in SDK log lines. Defense-in-depth
    # for any path that flows through execute_request with a sensitive
    # query parameter (most WorkOS-issued tokens are path segments or POST
    # bodies, but a few flows — e.g. authorize/logout redirects — surface
    # them in the query string).
    REDACTED_QUERY_KEYS = %w[
      token
      code
      code_challenge
      code_verifier
      session_id
      refresh_token
      access_token
    ].freeze
    private_constant :REDACTED_QUERY_KEYS

    def redact_path(path)
      return path if path.nil? || path.empty?

      # Strip query string for the prefix match; reattach (scrubbed) after.
      path_only, query = path.split("?", 2)
      REDACTED_TOKEN_PREFIXES.each do |prefix|
        next unless path_only.start_with?("#{prefix}/")

        # Replace every segment after the matched prefix with "[REDACTED]".
        remainder = path_only[(prefix.length + 1)..]
        next if remainder.nil? || remainder.empty?

        redacted = remainder.split("/").map { "[REDACTED]" }.join("/")
        path_only = "#{prefix}/#{redacted}"
        break
      end
      query ? "#{path_only}?#{redact_query(query)}" : path_only
    end

    def redact_query(query)
      return query if query.nil? || query.empty?

      query.split("&").map { |pair|
        key, value = pair.split("=", 2)
        if value && !value.empty? && REDACTED_QUERY_KEYS.include?(key)
          "#{key}=[REDACTED]"
        else
          pair
        end
      }.join("&")
    end

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

    # Per-fiber connection cache (non-inherited).
    #
    # Uses Thread.current[] (Ruby fiber-local storage) rather than
    # Fiber[] (inheritable fiber storage). Fiber[] is inherited *by
    # reference* by every child fiber and every child thread, so a live
    # Net::HTTP socket cached in a parent fiber would be shared across
    # worker threads spawned afterward (e.g. Solid Queue, Puma). Net::HTTP
    # sockets are not thread-safe; concurrent use corrupts the stream and
    # surfaces as FrozenError on the SSLContext, Errno::EBADF, "stream
    # closed in another thread" (IOError), and Net::HTTPBadResponse.
    # Thread.current[] is not inherited across threads, so each thread
    # gets its own isolated cache.
    #
    # Note: Thread.current[] is fiber-local in Ruby — each Fiber within a
    # thread has its own slot. In fiber-based servers (Async, Falcon) this
    # means one connection cache per fiber rather than per OS thread, which
    # is the desired behavior: each concurrent request gets its own sockets.
    def thread_connections
      Thread.current[:workos_connections] ||= {}
    end

    def build_request(klass, path, auth:, request_options:)
      opts = request_options.is_a?(Hash) ? request_options : {}
      request = klass.new(path)
      client_credentials = false
      if auth
        key = opts[:api_key] || opts["api_key"]
        if key
          # A per-request key keeps its precedence over the client's
          # credentials, and a 401 on it is not recoverable.
          request["Authorization"] = "Bearer #{key}" unless key.empty?
        else
          client_credentials = true
          # A static key never blocks, so its header is set here, where it
          # has always been set. Other credentials may need an exchange and
          # are resolved per attempt in execute_request.
          apply_snapshot(request, @credentials.resolve) if @credentials.is_a?(StaticKeyCredentials)
        end
      end
      request["User-Agent"] = USER_AGENT
      # Apply user headers before idempotency injection so caller-supplied
      # Idempotency-Key values win.
      apply_extra_headers(request, request_options)
      # A caller-supplied Authorization header is a per-request override too.
      if client_credentials && !extra_authorization?(request_options)
        request.instance_variable_set(CLIENT_CREDENTIALS, true)
      end
      request
    end

    # Resolve the client's credentials and set their headers on the request.
    # Returns nil for a request that does not use them: `auth: false`, or a
    # per-request override.
    def authorize(request, timeout)
      return nil unless request.instance_variable_get(CLIENT_CREDENTIALS)

      snapshot = @credentials.resolve(timeout: timeout)
      # A static key's header was set when the request was built and is left
      # alone from then on, including anything the caller did to it since.
      apply_snapshot(request, snapshot) unless @credentials.is_a?(StaticKeyCredentials)
      snapshot
    end

    def apply_snapshot(request, snapshot)
      snapshot.headers.each { |name, value| request[name] = value }
    end

    def extra_authorization?(request_options)
      return false unless request_options.is_a?(Hash)

      extra = request_options[:extra_headers] || request_options["extra_headers"]
      extra.is_a?(Hash) && extra.any? { |name, _value| name.to_s.casecmp?("authorization") }
    end

    # A 401 is worth one re-resolve when the credentials that were sent say so.
    def recoverable_unauthorized?(response, snapshot)
      response.code.to_i == 401 && !snapshot.nil? && snapshot.recoverable
    end

    # One HTTP attempt on this thread's pooled connection.
    def transmit(request, base, timeout)
      http = connection_for(base, timeout)
      request_completed = false
      begin
        response = http.request(request)
        request_completed = true
        response
      ensure
        # Any exit from #request other than a returned response can leave
        # the socket mid-stream: a connection error the caller's rescue knows
        # about, one it doesn't (OpenSSL::SSL::SSLError,
        # Net::HTTPBadResponse), or a non-local exit such as an
        # application-level Timeout.timeout or Thread#kill. A half-read
        # socket handed back to the pool desyncs the *next* request on this
        # thread, so drop it here rather than in the rescue.
        evict_connection(base) unless request_completed
      end
    end

    def apply_extra_headers(request, request_options)
      return unless request_options.is_a?(Hash)

      extra = request_options[:extra_headers] || request_options["extra_headers"]
      return unless extra.is_a?(Hash)

      extra.each { |k, v| request[k.to_s] = v.to_s }
    end

    def inject_idempotency_key(request, request_options)
      opts = request_options.is_a?(Hash) ? request_options : {}
      key = opts[:idempotency_key] || opts["idempotency_key"]
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
      BaseClient.retry_delay(response, attempt, @random)
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
