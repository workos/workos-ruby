# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained runtime
require "json"
require "net/http"
require "timeout"
require "uri"
require "workos/errors"

module WorkOS
  module WorkloadIdentity
    # Credentials that exchange a workload's identity token (a JWT from
    # GitHub Actions, GCP, AWS, a file, an environment variable or any
    # callable) for a short-lived WorkOS access token, and keep that token
    # fresh.
    #
    # Pass an instance to `WorkOS::Client.new(credentials: ...)`. The token
    # is cached on the instance, in memory only. It is exchanged on first
    # use and again, on demand, once less than
    # min(60 seconds, 20% of its lifetime) remains. Concurrent callers share
    # one exchange.
    #
    # Configuration is fixed at construction. To change a setting, build a
    # new instance.
    #
    # @example
    #   credentials = WorkOS::WorkloadIdentity::Credentials.new(
    #     client_id: "client_...",
    #     token_url: "https://.../oauth2/token",
    #     environment_id: "environment_...",
    #     identity_token_provider: -> { fetch_my_jwt }
    #   )
    #   client = WorkOS::Client.new(credentials: credentials)
    class Credentials
      # One exchange in progress, shared by every caller that arrives while
      # it runs. Guarded by the credentials' mutex.
      Exchange = Struct.new(:thread, :done, :token, :generation, :error)
      private_constant :Exchange

      # Why the last exchange attempt did not produce a token.
      Failure = Struct.new(:code, :description, :cause)
      private_constant :Failure

      attr_reader :client_id, :token_url, :environment_id, :resource, :scope

      # @param identity_token_provider [#call] Returns the workload's JWT as
      #   a String. Called once per exchange attempt.
      # @param client_id [String, nil] The M2M application's client ID.
      #   Defaults to `WORKOS_CLIENT_ID`.
      # @param token_url [String, nil] The token exchange endpoint. Defaults
      #   to `WORKOS_WIF_TOKEN_URL`; there is no built-in default.
      # @param environment_id [String, nil] Optional. Defaults to
      #   `WORKOS_ENVIRONMENT_ID`; an empty string counts as not set. The
      #   server binds a workload identity client to exactly one environment
      #   and takes the environment from that binding, so this selects
      #   nothing. Setting it is a safety check: it is sent as the
      #   `x-url-environment-id` header on every API request, and a value
      #   that names a different environment gets `403 environment_mismatch`.
      #   When it is not set, the header is not sent.
      # @param resource [String, nil] Defaults to `https://api.workos.com`.
      # @param scope [String, nil] Defaults to `WORKOS_WIF_SCOPE`; left out
      #   of the exchange when empty.
      # @param clock [#call] Returns the current time in seconds. For tests.
      # @param sleeper [#call] Waits the given number of seconds between
      #   exchange attempts. For tests.
      # @param random [Random] Source of backoff jitter. For tests.
      # @raise [WorkOS::WorkloadIdentityError] with code
      #   `invalid_configuration` when a required setting is missing.
      def initialize(identity_token_provider: nil, client_id: nil, token_url: nil,
        environment_id: nil, resource: nil, scope: nil,
        clock: nil, sleeper: nil, random: Random.new)
        @client_id = required("client_id", client_id, "WORKOS_CLIENT_ID")
        @token_url = required("token_url", token_url, "WORKOS_WIF_TOKEN_URL")
        @environment_id = presence(environment_id.nil? ? ENV["WORKOS_ENVIRONMENT_ID"] : environment_id)&.dup&.freeze
        @resource = (presence(resource) || DEFAULT_RESOURCE).dup.freeze
        @scope = presence(scope.nil? ? ENV["WORKOS_WIF_SCOPE"] : scope)&.dup&.freeze
        @token_uri = parse_token_url(@token_url)
        unless identity_token_provider.respond_to?(:call)
          raise invalid_configuration("identity_token_provider is required and must respond to call")
        end
        @provider = identity_token_provider

        @clock = clock || -> { monotonic }
        @sleeper = sleeper || ->(seconds) { sleep(seconds) }
        @random = random
        @max_retries = BaseClient::DEFAULT_MAX_RETRIES

        @mutex = Mutex.new
        @settled = ConditionVariable.new
        @token = nil
        @lifetime = 0
        @expires_at = -Float::INFINITY
        @generation = 0
        @inflight = nil
      end

      # The headers for one HTTP attempt. Returns the cached token while it
      # is fresh; otherwise waits for the one shared exchange.
      #
      # @param timeout [Numeric, nil] Seconds this caller is willing to wait
      #   for an exchange. Giving up does not stop the exchange.
      # @return [WorkOS::CredentialSnapshot]
      # @raise [WorkOS::WorkloadIdentityError] when the exchange fails.
      # @raise [WorkOS::APIConnectionError] when `timeout` runs out first.
      def resolve(timeout: nil)
        token, generation = current_token(timeout)
        headers = {"Authorization" => "Bearer #{token}"}
        headers[ENVIRONMENT_HEADER] = @environment_id if @environment_id
        CredentialSnapshot.new(
          headers: headers.freeze,
          generation: generation,
          recoverable: true
        )
      end

      # Discard the token of the given generation, so the next {#resolve}
      # exchanges again. Does nothing when a newer token is already cached,
      # which is what keeps a late 401 for an old token from throwing away a
      # good one.
      def invalidate(generation)
        @mutex.synchronize do
          @expires_at = -Float::INFINITY if @generation == generation
        end
        nil
      end

      # Never includes the cached token.
      def inspect
        "#<#{self.class.name} client_id=#{@client_id.inspect} token_url=#{@token_url.inspect} environment_id=#{@environment_id.inspect}>"
      end

      private

      # -- Configuration ----------------------------------------------------

      def required(field, explicit, env_name)
        value = presence(explicit.nil? ? ENV[env_name] : explicit)
        raise invalid_configuration("#{field} is required (or set #{env_name})") if value.nil?

        value.dup.freeze
      end

      def presence(value)
        return nil if value.nil?

        value = value.to_s.strip
        value.empty? ? nil : value
      end

      def parse_token_url(token_url)
        uri = begin
          URI.parse(token_url)
        rescue URI::InvalidURIError
          nil
        end
        unless uri.is_a?(URI::HTTP) && uri.hostname && !uri.hostname.empty?
          raise invalid_configuration("token_url must be an http or https URL")
        end

        uri
      end

      def invalid_configuration(description)
        WorkloadIdentityError.new(code: "invalid_configuration", description: description)
      end

      # -- Cache ------------------------------------------------------------

      def current_token(timeout)
        @mutex.synchronize do
          return [@token, @generation] if fresh?

          wait_for(join_or_start_exchange, timeout)
        end
      end

      # Called with the lock held.
      def fresh?
        return false if @token.nil?

        threshold = [REFRESH_THRESHOLD, REFRESH_FRACTION * @lifetime].min
        (@expires_at - @clock.call) >= threshold
      end

      # -- Shared exchange --------------------------------------------------

      # Called with the lock held. Returns the exchange to wait on.
      def join_or_start_exchange
        call = @inflight
        return call if call&.thread&.alive?

        # The slot is held by an exchange whose thread is gone without having
        # settled it: the process forked, and threads do not survive a fork.
        settle(call, error: interrupted) if call

        call = Exchange.new
        call.thread = Thread.new { run_exchange(call) }
        call.thread.name = "workos-workload-identity-exchange"
        call.thread.report_on_exception = false
        @inflight = call
      end

      # Called with the lock held; the wait releases it. `call` is this
      # caller's own reference and is never re-read from @inflight.
      def wait_for(call, timeout)
        give_up_at = timeout && (monotonic + timeout)
        until call.done
          remaining = give_up_at && (give_up_at - monotonic)
          if remaining && remaining <= 0
            # Only this caller stops waiting. The exchange keeps running for
            # the others and still fills the cache.
            raise APIConnectionError.new(message: "Timed out after #{timeout}s waiting for the workload identity token exchange")
          end
          @settled.wait(@mutex, remaining)
        end

        if (error = call.error)
          # A fresh error per caller, so each gets its own backtrace.
          raise WorkloadIdentityError.new(code: error.code, description: error.description), cause: error.cause
        end
        [call.token, call.generation]
      end

      # Runs on its own thread, under its own deadline, so that no caller's
      # timeout, interrupt or death can cancel the exchange the others are
      # waiting on.
      def run_exchange(call)
        token = lifetime = error = nil
        begin
          token, lifetime = Timeout.timeout(EXCHANGE_DEADLINE) { exchange }
        rescue WorkloadIdentityError => e
          error = e
        rescue Timeout::Error
          error = WorkloadIdentityError.new(code: "exchange_failed", description: "the exchange did not finish within #{EXCHANGE_DEADLINE} seconds")
        rescue => e
          error = WorkloadIdentityError.new(code: "exchange_failed", description: e.class.name)
        ensure
          # Also reached when the thread is killed, so the slot is always freed.
          @mutex.synchronize { settle(call, token: token, lifetime: lifetime, error: error) }
        end
      end

      # Called with the lock held. Stores the token (on success), frees the
      # in-flight slot and wakes the waiters, all in one locked section: a
      # caller that wakes up with an error and calls again starts a new
      # exchange and can never join this finished one.
      def settle(call, token: nil, lifetime: nil, error: nil)
        return if call.done

        if token
          @token = token
          @lifetime = lifetime
          @expires_at = @clock.call + lifetime
          @generation += 1
          call.token = token
          call.generation = @generation
        else
          call.error = error || interrupted
        end
        call.done = true
        @inflight = nil if @inflight.equal?(call)
        @settled.broadcast
      end

      def interrupted
        WorkloadIdentityError.new(code: "exchange_failed", description: "the exchange was interrupted before it finished")
      end

      # -- Exchange ---------------------------------------------------------

      # One exchange: up to 1 + max_retries attempts. A failing provider, a
      # transport failure, a 429 and a 5xx are retried, and the provider is
      # asked for a token again on every attempt. Anything else is final.
      #
      # @return [Array(String, Numeric)] access token and lifetime in seconds
      def exchange
        started = monotonic
        failure = nil
        throttled = nil

        (0..@max_retries).each do |attempt|
          if attempt.positive?
            delay = BaseClient.retry_delay(throttled, attempt, @random)
            break if delay > EXCHANGE_DEADLINE - (monotonic - started)

            @sleeper.call(delay)
          end
          throttled = nil

          assertion = begin
            identity_token
          rescue => e
            failure = Failure.new("provider_failed", provider_failure(e), e)
            next
          end

          response = begin
            post_form(assertion, EXCHANGE_DEADLINE - (monotonic - started))
          rescue => e
            failure = Failure.new("exchange_failed", "#{e.class}: #{e.message}", e)
            next
          end

          # The status is checked before the body: a 429 or 5xx is retried
          # even when its body carries an OAuth error.
          status = response.code.to_i
          if status == 429 || status >= 500
            throttled = response
            code, description = oauth_error(response, assertion)
            failure = Failure.new(code || "exchange_failed", description || "HTTP #{status}", nil)
            next
          end

          return read_token(response, assertion)
        end

        raise WorkloadIdentityError.new(code: failure.code, description: failure.description), cause: failure.cause
      end

      def identity_token
        token = @provider.call
        token = token.strip if token.is_a?(String)
        unless token.is_a?(String) && !token.empty?
          raise WorkloadIdentityError.new(code: "provider_failed", description: "the identity token provider returned no token")
        end

        token
      end

      def provider_failure(error)
        error.is_a?(WorkloadIdentityError) ? error.description : "#{error.class}: #{error.message}"
      end

      # No client secret, no Authorization header and no API key: the
      # assertion is the only credential. Net::HTTP does not follow redirects.
      def post_form(assertion, time_left)
        form = {
          "grant_type" => GRANT_TYPE,
          "assertion" => assertion,
          "client_id" => @client_id,
          "resource" => @resource
        }
        form["scope"] = @scope if @scope

        request = Net::HTTP::Post.new(@token_uri.request_uri)
        request["Content-Type"] = "application/x-www-form-urlencoded"
        request["Accept"] = "application/json"
        request["User-Agent"] = BaseClient::USER_AGENT
        request.body = URI.encode_www_form(form)

        timeout = time_left.clamp(0.001, BaseClient::DEFAULT_TIMEOUT)
        http = Net::HTTP.new(@token_uri.hostname, @token_uri.port)
        http.use_ssl = (@token_uri.scheme == "https")
        http.open_timeout = timeout
        http.read_timeout = timeout
        http.write_timeout = timeout
        http.max_retries = 0
        http.start { |connection| connection.request(request) }
      end

      # A response that is neither a 429 nor a 5xx: a token, or a final error.
      def read_token(response, assertion)
        status = response.code.to_i
        code, description = oauth_error(response, assertion)
        raise WorkloadIdentityError.new(code: code, description: description) if code

        if (300..399).cover?(status)
          raise WorkloadIdentityError.new(code: "exchange_failed", description: "HTTP #{status}: the token endpoint redirected, and redirects are not followed")
        end

        body = json_object(response)
        unless status == 200 && body
          raise WorkloadIdentityError.new(code: "invalid_response", description: (status == 200) ? "the response was not a JSON object" : "HTTP #{status}")
        end

        token = body["access_token"]
        unless token.is_a?(String) && !token.empty?
          raise WorkloadIdentityError.new(code: "invalid_response", description: "the response had no access_token")
        end

        expires_in = body["expires_in"]
        usable = expires_in.is_a?(Numeric) && expires_in.finite? && expires_in.positive?
        [token, usable ? expires_in : DEFAULT_LIFETIME]
      end

      # The OAuth `error` and `error_description` of a response, when its
      # body has them. The assertion is scrubbed in case the server echoed it.
      def oauth_error(response, assertion)
        body = json_object(response)
        code = body && body["error"]
        return nil unless code.is_a?(String) && !code.empty?

        description = body["error_description"]
        description = "" unless description.is_a?(String)
        [code.gsub(assertion, "[REDACTED]"), description.gsub(assertion, "[REDACTED]")]
      end

      def json_object(response)
        parsed = JSON.parse(response.body.to_s)
        parsed.is_a?(Hash) ? parsed : nil
      rescue JSON::ParserError
        nil
      end

      def monotonic
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
