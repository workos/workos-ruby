# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained signatures for lib/workos/base_client.rb

# typed: strong

module WorkOS
  class BaseClient
    DEFAULT_BASE_URL = T.let(T.unsafe(nil), String)
    DEFAULT_TIMEOUT = T.let(T.unsafe(nil), Integer)
    DEFAULT_MAX_RETRIES = T.let(T.unsafe(nil), Integer)
    RETRYABLE_STATUSES = T.let(T.unsafe(nil), T::Array[Integer])
    MAX_CACHED_CONNECTIONS = T.let(T.unsafe(nil), Integer)
    RETRY_BACKOFF_BASE = T.let(T.unsafe(nil), Float)
    LOG_SEVERITY = T.let(T.unsafe(nil), T::Hash[Symbol, Integer])
    USER_AGENT = T.let(T.unsafe(nil), String)

    sig { returns(T.nilable(String)) }
    def api_key; end

    # Anything that responds to `resolve` and `invalidate`: the credentials
    # passed to the constructor, or the client's own wrapper around its API
    # key.
    sig { returns(T.untyped) }
    def credentials; end

    sig { returns(String) }
    def base_url; end

    sig { returns(T.nilable(String)) }
    def client_id; end

    sig { returns(Numeric) }
    def timeout; end

    sig { returns(Integer) }
    def max_retries; end

    # A Logger, or anything with its `debug`/`info`/`warn`/`error` or `add`.
    sig { returns(T.untyped) }
    def logger; end

    sig { returns(T.nilable(Symbol)) }
    def log_level; end

    sig { returns(T.nilable(T.any(String, T::Array[String]))) }
    def jwt_issuer; end

    sig { params(response: T.nilable(Net::HTTPResponse), attempt: Integer, random: Random).returns(Float) }
    def self.retry_delay(response, attempt, random); end

    sig do
      params(
        api_key: T.nilable(String),
        credentials: T.untyped,
        base_url: String,
        client_id: T.nilable(String),
        timeout: Numeric,
        max_retries: Integer,
        logger: T.untyped,
        log_level: T.nilable(Symbol),
        jwt_issuer: T.nilable(T.any(String, T::Array[String])),
        random: Random
      ).void
    end
    def initialize(api_key: nil, credentials: nil, base_url: DEFAULT_BASE_URL, client_id: nil, timeout: DEFAULT_TIMEOUT, max_retries: DEFAULT_MAX_RETRIES, logger: nil, log_level: nil, jwt_issuer: nil, random: Random.new); end

    sig do
      params(
        path: String,
        auth: T::Boolean,
        params: T.nilable(T::Hash[T.any(Symbol, String), T.untyped]),
        request_options: T.nilable(T::Hash[T.any(Symbol, String), T.untyped])
      ).returns(Net::HTTP::Get)
    end
    def get_request(path:, auth: false, params: {}, request_options: nil); end

    sig do
      params(
        path: String,
        auth: T::Boolean,
        body: T.untyped,
        params: T.nilable(T::Hash[T.any(Symbol, String), T.untyped]),
        request_options: T.nilable(T::Hash[T.any(Symbol, String), T.untyped])
      ).returns(Net::HTTP::Post)
    end
    def post_request(path:, auth: false, body: {}, params: {}, request_options: nil); end

    sig do
      params(
        path: String,
        auth: T::Boolean,
        body: T.untyped,
        params: T.nilable(T::Hash[T.any(Symbol, String), T.untyped]),
        request_options: T.nilable(T::Hash[T.any(Symbol, String), T.untyped])
      ).returns(Net::HTTP::Put)
    end
    def put_request(path:, auth: false, body: {}, params: {}, request_options: nil); end

    sig do
      params(
        path: String,
        auth: T::Boolean,
        body: T.untyped,
        params: T.nilable(T::Hash[T.any(Symbol, String), T.untyped]),
        request_options: T.nilable(T::Hash[T.any(Symbol, String), T.untyped])
      ).returns(Net::HTTP::Patch)
    end
    def patch_request(path:, auth: false, body: {}, params: {}, request_options: nil); end

    sig do
      params(
        path: String,
        auth: T::Boolean,
        body: T.untyped,
        params: T.nilable(T::Hash[T.any(Symbol, String), T.untyped]),
        request_options: T.nilable(T::Hash[T.any(Symbol, String), T.untyped])
      ).returns(Net::HTTP::Delete)
    end
    def delete_request(path:, auth: false, body: nil, params: {}, request_options: nil); end

    # Returns the response of a successful request; raises a WorkOS::Error
    # otherwise.
    sig do
      params(
        method: Symbol,
        path: String,
        auth: T::Boolean,
        params: T.nilable(T::Hash[T.any(Symbol, String), T.untyped]),
        body: T.untyped,
        request_options: T.nilable(T::Hash[T.any(Symbol, String), T.untyped])
      ).returns(Net::HTTPResponse)
    end
    def request(method:, path:, auth: true, params: {}, body: nil, request_options: {}); end

    sig do
      params(
        request: Net::HTTPRequest,
        request_options: T.nilable(T::Hash[T.any(Symbol, String), T.untyped])
      ).returns(Net::HTTPResponse)
    end
    def execute_request(request:, request_options: nil); end

    sig { void }
    def shutdown; end
  end
end
