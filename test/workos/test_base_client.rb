# frozen_string_literal: true

require "test_helper"
require "time"

class BaseClientTest < Minitest::Test
  class RecordingClient < WorkOS::BaseClient
    attr_reader :calls

    def initialize(**kwargs)
      super
      @calls = []
    end

    def get_request(**kwargs)
      @calls << [:get, kwargs]
      Net::HTTP::Get.new(kwargs[:path])
    end

    def post_request(**kwargs)
      @calls << [:post, kwargs]
      Net::HTTP::Post.new(kwargs[:path])
    end

    def put_request(**kwargs)
      @calls << [:put, kwargs]
      Net::HTTP::Put.new(kwargs[:path])
    end

    def patch_request(**kwargs)
      @calls << [:patch, kwargs]
      Net::HTTP::Patch.new(kwargs[:path])
    end

    def delete_request(**kwargs)
      @calls << [:delete, kwargs]
      Net::HTTP::Delete.new(kwargs[:path])
    end

    def execute_request(request:, request_options: nil)
      [request.method, request_options]
    end
  end

  class CapturingLogger
    attr_reader :events

    def initialize
      @events = []
    end

    def debug(message)
      @events << [:debug, message]
    end

    def info(message)
      @events << [:info, message]
    end

    def warn(message)
      @events << [:warn, message]
    end

    def error(message)
      @events << [:error, message]
    end
  end

  class FakeConnection
    attr_reader :finished

    def initialize(started: true)
      @started = started
      @finished = false
    end

    def started?
      @started
    end

    def finish
      @finished = true
    end
  end

  # A pooled connection that either returns a canned response or raises when
  # driven, so execute_request can be exercised without real TCP+TLS.
  class StubConnection < FakeConnection
    attr_accessor :read_timeout, :open_timeout

    def initialize(response: nil, error: nil, **kwargs)
      super(**kwargs)
      @response = response
      @error = error
    end

    def request(_request)
      raise @error if @error

      @response
    end
  end

  def setup
    @client = WorkOS::BaseClient.new(api_key: "sk_test_123", max_retries: 1)
  end

  def teardown
    super
    # Close any open connections and clear the thread-local cache to avoid
    # leaking sockets between tests.
    @client.shutdown
    Thread.current[:workos_connections] = nil
  end

  def test_request_dispatches_known_methods
    client = RecordingClient.new(api_key: "sk_test_123")

    assert_equal ["GET", {timeout: 5}], client.request(method: :get, path: "/get", request_options: {timeout: 5})
    assert_equal ["POST", {}], client.request(method: :post, path: "/post", body: {ok: true})
    assert_equal ["PUT", {}], client.request(method: :put, path: "/put", body: {ok: true})
    assert_equal ["PATCH", {}], client.request(method: :patch, path: "/patch", body: {ok: true})
    assert_equal ["DELETE", {}], client.request(method: :delete, path: "/delete")
    assert_equal %i[get post put patch delete], client.calls.map(&:first)
  end

  def test_request_rejects_unknown_method
    error = assert_raises(ArgumentError) do
      @client.request(method: :trace, path: "/widgets")
    end

    assert_equal "unsupported method", error.message
  end

  def test_post_request_reads_idempotency_key_from_request_options
    request = @client.post_request(path: "/widgets", auth: true, body: {name: "widget"}, request_options: {idempotency_key: "idem_123"})

    assert_equal "idem_123", request["Idempotency-Key"]
  end

  # The body is serialized verbatim (no `.compact`), so an explicit `nil` is
  # sent as JSON `null` — this is what lets generated methods clear a nullable
  # field. Omission is handled upstream in the generated method, not here.
  def test_put_request_serializes_explicit_nil_as_json_null
    request = @client.put_request(path: "/widgets/w_1", auth: true, body: {"external_id" => nil})

    assert_equal({"external_id" => nil}, JSON.parse(request.body))
  end

  def test_post_request_serializes_explicit_nil_as_json_null
    request = @client.post_request(path: "/widgets", auth: true, body: {"external_id" => nil})

    assert_equal({"external_id" => nil}, JSON.parse(request.body))
  end

  def test_patch_request_serializes_explicit_nil_as_json_null
    request = @client.patch_request(path: "/widgets/w_1", auth: true, body: {"external_id" => nil})

    assert_equal({"external_id" => nil}, JSON.parse(request.body))
  end

  def test_delete_request_serializes_explicit_nil_as_json_null
    request = @client.delete_request(path: "/widgets/w_1", auth: true, body: {"external_id" => nil})

    assert_equal({"external_id" => nil}, JSON.parse(request.body))
  end

  def test_post_sends_one_idempotency_key_on_the_first_attempt_and_its_retries
    stub_request(:post, "https://api.workos.com/widgets")
      .to_return({status: 500, body: '{"message":"retry"}'}, {status: 200, body: "{}"})

    @client.singleton_class.define_method(:sleep) { |_duration| nil }
    @client.request(method: :post, path: "/widgets", body: {name: "widget"})

    assert_requested(:post, "https://api.workos.com/widgets", headers: {"Idempotency-Key" => /.+/}, times: 2)
    keys = WebMock::RequestRegistry.instance.requested_signatures.hash.keys.map { |signature| signature.headers["Idempotency-Key"] }
    assert_equal 1, keys.uniq.size
  end

  # Retry-After is either a number of seconds or an HTTP-date. A date used to
  # be ignored, so the client retried on its normal backoff and could run out
  # of attempts before the server was ready.
  def test_retry_waits_until_an_http_date_retry_after
    stub_request(:get, "https://api.workos.com/widgets")
      .to_return(
        {status: 503, headers: {"Retry-After" => (Time.now + 120).httpdate}, body: "{}"},
        {status: 200, body: "{}"}
      )
    sleeps = []
    @client.singleton_class.define_method(:sleep) { |duration| sleeps << duration }

    @client.request(method: :get, path: "/widgets")

    assert_equal 1, sleeps.size
    assert_in_delta 120, sleeps.first, 2
  end

  def test_retry_delay_reads_retry_after_in_seconds
    assert_equal 7.0, @client.send(:retry_delay, response_with_retry_after("7"), 1)
  end

  def test_retry_delay_falls_back_to_backoff_for_an_unusable_retry_after
    client = WorkOS::BaseClient.new(api_key: "sk_test_123", random: Struct.new(:rand).new(0.0))

    [(Time.now - 60).httpdate, "soon", "0", "-5", nil].each do |value|
      delay = client.send(:retry_delay, response_with_retry_after(value), 1)

      assert_equal WorkOS::BaseClient::RETRY_BACKOFF_BASE, delay, "expected Retry-After #{value.inspect} to be ignored"
    end
  end

  def response_with_retry_after(value)
    response = Net::HTTPServiceUnavailable.new("1.1", "503", "Service Unavailable")
    response["Retry-After"] = value if value
    response
  end

  def test_409_idempotency_error_raises_specific_error
    stub_request(:post, "https://api.workos.com/widgets")
      .to_return(status: 409, body: '{"code":"idempotency_error","message":"conflict"}')

    assert_raises(WorkOS::IdempotencyError) do
      @client.request(method: :post, path: "/widgets", body: {name: "widget"})
    end
  end

  def test_api_error_rescues_http_errors_but_not_connection_errors
    stub_request(:get, "https://api.workos.com/widgets")
      .to_return(status: 401, body: '{"message":"Unauthorized"}')

    raised = assert_raises(WorkOS::APIError) do
      @client.request(method: :get, path: "/widgets")
    end

    assert_kind_of WorkOS::AuthenticationError, raised
    refute WorkOS::APIConnectionError <= WorkOS::APIError
    refute WorkOS::SignatureVerificationError <= WorkOS::APIError
  end

  def test_log_level_is_a_threshold
    logger = CapturingLogger.new
    client = WorkOS::BaseClient.new(api_key: "sk_test_123", logger: logger, log_level: :warn)

    client.send(:log, :debug, "debug line")
    client.send(:log, :info, "info line")
    client.send(:log, :warn, "warn line")
    client.send(:log, :error, "error line")

    assert_equal [[:warn, "warn line"], [:error, "error line"]], logger.events
  end

  def test_evict_connection_removes_matching_pooled_connections
    keep = FakeConnection.new
    evict = FakeConnection.new
    thread_connections = @client.send(:thread_connections)
    thread_connections["https:api.workos.com:443:30"] = evict
    thread_connections["https:other.workos.com:443:30"] = keep

    @client.send(:evict_connection, "https://api.workos.com")

    refute thread_connections.key?("https:api.workos.com:443:30")
    assert thread_connections.key?("https:other.workos.com:443:30")
    assert evict.finished
    refute keep.finished
  end

  # An exception execute_request's rescue clause doesn't list still leaves the
  # socket mid-stream, so the connection must not survive in the pool for the
  # next request on this thread to pick up.
  def test_unlisted_request_error_evicts_the_pooled_connection
    conn = StubConnection.new(error: Net::HTTPBadResponse.new("wrong version"))
    cache = @client.send(:thread_connections)
    cache["https:api.workos.com:443:30"] = conn

    assert_raises(Net::HTTPBadResponse) do
      @client.execute_request(request: Net::HTTP::Get.new("/things"))
    end

    refute cache.key?("https:api.workos.com:443:30"),
      "a connection whose request did not complete must not stay pooled"
    assert conn.finished
  end

  def test_completed_request_keeps_the_connection_pooled
    conn = StubConnection.new(response: Net::HTTPOK.new("1.1", "200", "OK"))
    cache = @client.send(:thread_connections)
    cache["https:api.workos.com:443:30"] = conn

    @client.execute_request(request: Net::HTTP::Get.new("/things"))

    assert cache.key?("https:api.workos.com:443:30")
    refute conn.finished
  end

  # Raised asynchronously into the worker thread to stand in for a caller-side
  # abort: Timeout.timeout, Thread#kill, a signal handler unwinding the stack.
  # It descends from Exception rather than StandardError so that nothing in
  # execute_request can catch it — the `ensure` is the only cleanup that runs.
  class AbortSignal < Exception; end # standard:disable Lint/InheritException

  # End-to-end regression test over a real keep-alive socket, for the failure
  # the eviction actually prevents: request one is abandoned mid-flight, the
  # server then writes response one onto that socket, and request two on the
  # same thread reads those stale bytes as if they were its own response.
  #
  # Before the fix, request two sees marker "one" (or a mangled response) off
  # the pooled socket. After it, the abandoned socket is closed and the server
  # accepts a fresh connection for request two.
  def test_aborted_request_does_not_leak_its_response_to_the_next_request
    WebMock.disable!
    server = TCPServer.new("127.0.0.1", 0)
    port = server.addr[1]
    client = WorkOS::BaseClient.new(
      api_key: "sk_test_123",
      base_url: "http://127.0.0.1:#{port}",
      timeout: 5,
      max_retries: 0
    )

    request_one_read = Queue.new
    release_response_one = Queue.new
    response_one_written = Queue.new
    aborted = Queue.new
    connections = Queue.new

    server_thread = Thread.new do
      # Connection one: read the request, then hold the response back until
      # the client has been aborted and has unwound.
      first = server.accept
      connections << first
      read_http_request(first)
      request_one_read << true
      release_response_one.pop
      begin
        write_http_response(first, {marker: "one"})
      rescue Errno::EPIPE, Errno::ECONNRESET, IOError
        # Expected once the fix closes the abandoned socket.
      end
      response_one_written << true

      # Connection two: a fresh accept, which only completes because the
      # client did not reuse the socket above.
      second = server.accept
      connections << second
      read_http_request(second)
      write_http_response(second, {marker: "two"})
    end

    worker = Thread.new do
      begin
        client.execute_request(request: Net::HTTP::Get.new("/one"))
      rescue AbortSignal
        # The caller unwinds but the thread survives and goes on to serve more
        # work, the way a Puma or Solid Queue worker does. execute_request's
        # `ensure` has already run by the time this body executes.
        aborted << true
        response_one_written.pop
      end
      response = client.execute_request(request: Net::HTTP::Get.new("/two"))
      JSON.parse(response.body)["marker"]
    end

    marker = Timeout.timeout(15) do
      request_one_read.pop
      worker.raise(AbortSignal)
      aborted.pop
      release_response_one << true
      worker.value
    end

    assert_equal "two", marker,
      "request two read the abandoned socket's response instead of its own"
  ensure
    server_thread&.kill
    worker&.kill
    until connections.nil? || connections.empty?
      socket = connections.pop
      socket.close unless socket.closed?
    end
    server&.close
    WebMock.enable!
  end

  # Reads one request's head off the socket and returns its request line.
  def read_http_request(socket)
    request_line = socket.gets
    loop do
      line = socket.gets
      break if line.nil? || line == "\r\n"
    end
    request_line
  end

  def write_http_response(socket, body)
    payload = JSON.generate(body)
    socket.write(
      "HTTP/1.1 200 OK\r\n" \
      "Content-Type: application/json\r\n" \
      "Content-Length: #{payload.bytesize}\r\n" \
      "Connection: keep-alive\r\n" \
      "\r\n#{payload}"
    )
    socket.flush
  end

  # Regression test for https://github.com/workos/workos-ruby/issues/496
  #
  # The connection cache must be isolated per thread. A previous version
  # keyed it on Fiber[] (inheritable fiber storage), which is inherited *by
  # reference* by child threads — so a Net::HTTP socket warmed in a parent
  # thread leaked into every worker thread spawned afterward (Solid Queue,
  # Puma, etc.) and got driven concurrently, corrupting the stream.
  def test_connection_cache_is_not_shared_with_threads_spawned_after_warming
    # Warm a connection in the "parent" thread before spawning workers.
    parent_cache = @client.send(:thread_connections)
    warm = FakeConnection.new
    parent_cache["https:api.workos.com:443:30"] = warm

    results = Array.new(4) do
      Thread.new do
        cache = @client.send(:thread_connections)
        {cache_id: cache.object_id, leaked: cache.value?(warm), size: cache.size}
      end
    end.map(&:value)

    results.each do |r|
      refute_equal parent_cache.object_id, r[:cache_id],
        "worker thread must not share the parent thread's connection cache"
      refute r[:leaked],
        "parent thread's warmed connection leaked into a worker thread"
      assert_equal 0, r[:size],
        "worker thread should start with an empty, isolated cache"
    end

    # The parent's own cache is left intact.
    assert_same warm, parent_cache["https:api.workos.com:443:30"]
  end

  def test_proxy_defaults_to_nil
    assert_nil @client.proxy
  end

  # Without an explicit proxy, Net::HTTP must keep reading http_proxy from
  # the environment exactly as it did before the option existed.
  def test_connection_without_proxy_still_reads_proxy_from_env
    with_stubbed_start do
      with_env("http_proxy" => "http://env-proxy.example.com:3128", "no_proxy" => nil) do
        conn = @client.send(:connection_for, "https://api.workos.com", 30)

        assert conn.proxy_from_env?
        assert conn.proxy?
        assert_equal "env-proxy.example.com", conn.proxy_address
        assert_equal 3128, conn.proxy_port
      end
    end
  end

  def test_connection_without_proxy_or_env_is_direct
    with_stubbed_start do
      with_env("http_proxy" => nil, "HTTP_PROXY" => nil) do
        conn = @client.send(:connection_for, "https://api.workos.com", 30)

        refute conn.proxy?
      end
    end
  end

  def test_connection_without_proxy_keeps_the_existing_cache_key
    uri = URI("https://api.workos.com")

    assert_equal "https:api.workos.com:443:30", @client.send(:connection_key, uri, 30)
  end

  def test_explicit_proxy_is_used_for_connections
    client = WorkOS::BaseClient.new(api_key: "sk_test_123", proxy: "http://proxy.example.com:8080")

    with_stubbed_start do
      conn = client.send(:connection_for, "https://api.workos.com", 30)

      refute conn.proxy_from_env?
      assert conn.proxy?
      assert_equal "proxy.example.com", conn.proxy_address
      assert_equal 8080, conn.proxy_port
      assert_nil conn.proxy_user
      assert_nil conn.proxy_pass
      assert conn.use_ssl?
      assert_equal "api.workos.com", conn.address
    end
  end

  def test_explicit_proxy_takes_precedence_over_env
    client = WorkOS::BaseClient.new(api_key: "sk_test_123", proxy: "http://proxy.example.com:8080")

    with_stubbed_start do
      with_env("http_proxy" => "http://env-proxy.example.com:3128", "no_proxy" => "api.workos.com") do
        conn = client.send(:connection_for, "https://api.workos.com", 30)

        assert conn.proxy?
        assert_equal "proxy.example.com", conn.proxy_address
        assert_equal 8080, conn.proxy_port
      end
    end
  end

  def test_explicit_proxy_credentials_are_percent_decoded
    client = WorkOS::BaseClient.new(api_key: "sk_test_123", proxy: "http://us%40er:p%3Ass+word@proxy.example.com:8080")

    with_stubbed_start do
      conn = client.send(:connection_for, "https://api.workos.com", 30)

      assert_equal "us@er", conn.proxy_user
      assert_equal "p:ss+word", conn.proxy_pass
    end
  end

  def test_explicit_proxy_accepts_a_uri_and_defaults_the_port
    client = WorkOS::BaseClient.new(api_key: "sk_test_123", proxy: URI("http://proxy.example.com"))

    with_stubbed_start do
      conn = client.send(:connection_for, "https://api.workos.com", 30)

      assert_equal "proxy.example.com", conn.proxy_address
      assert_equal 80, conn.proxy_port
    end
  end

  def test_proxy_reader_returns_the_configured_value
    client = WorkOS::BaseClient.new(api_key: "sk_test_123", proxy: "http://proxy.example.com:8080")

    assert_equal "http://proxy.example.com:8080", client.proxy
  end

  def test_invalid_proxy_raises_argument_error
    ["", "proxy.example.com:8080", "https://proxy.example.com", "socks5://proxy.example.com:1080", "http://", "http://bad host", 8080].each do |proxy|
      assert_raises(ArgumentError, "expected #{proxy.inspect} to be rejected") do
        WorkOS::BaseClient.new(api_key: "sk_test_123", proxy: proxy)
      end
    end
  end

  def test_invalid_proxy_error_does_not_leak_credentials
    error = assert_raises(ArgumentError) do
      WorkOS::BaseClient.new(api_key: "sk_test_123", proxy: "https://user:s3cret@proxy.example.com")
    end

    refute_includes error.message, "s3cret"
    refute_includes error.message, "user"
  end

  # Clients that differ only by proxy must not reuse each other's pooled
  # connection, otherwise traffic would silently take the wrong route.
  def test_clients_with_different_proxies_do_not_share_connections
    proxied = WorkOS::BaseClient.new(api_key: "sk_test_123", proxy: "http://proxy-a.example.com:8080")
    other = WorkOS::BaseClient.new(api_key: "sk_test_123", proxy: "http://proxy-b.example.com:8080")
    same = WorkOS::BaseClient.new(api_key: "sk_test_123", proxy: "http://proxy-a.example.com:8080")

    with_stubbed_start do
      with_env("http_proxy" => nil, "HTTP_PROXY" => nil) do
        direct_conn = @client.send(:connection_for, "https://api.workos.com", 30)
        proxied_conn = proxied.send(:connection_for, "https://api.workos.com", 30)
        other_conn = other.send(:connection_for, "https://api.workos.com", 30)

        refute direct_conn.proxy?
        assert_equal "proxy-a.example.com", proxied_conn.proxy_address
        assert_equal "proxy-b.example.com", other_conn.proxy_address
        assert_equal 3, [direct_conn, proxied_conn, other_conn].map(&:object_id).uniq.length
        assert_equal 3, Thread.current[:workos_connections].size

        # Asking again reuses each pooled connection, and a client configured
        # with the same proxy shares the entry.
        assert_same proxied_conn, proxied.send(:connection_for, "https://api.workos.com", 30)
        assert_same proxied_conn, same.send(:connection_for, "https://api.workos.com", 30)
        assert_same other_conn, other.send(:connection_for, "https://api.workos.com", 30)
        assert_same direct_conn, @client.send(:connection_for, "https://api.workos.com", 30)
        assert_equal 3, Thread.current[:workos_connections].size
      end
    end
  end

  def test_proxy_credentials_are_part_of_the_cache_key_but_not_stored_in_it
    uri = URI("https://api.workos.com")
    first = WorkOS::BaseClient.new(proxy: "http://user:s3cret@proxy.example.com:8080")
    second = WorkOS::BaseClient.new(proxy: "http://user:other@proxy.example.com:8080")

    first_key = first.send(:connection_key, uri, 30)

    refute_equal first_key, second.send(:connection_key, uri, 30)
    refute_includes first_key, "s3cret"
    assert first_key.start_with?("https:api.workos.com:443:30:")
  end

  def test_evict_connection_removes_proxied_connections
    client = WorkOS::BaseClient.new(api_key: "sk_test_123", proxy: "http://proxy.example.com:8080")
    key = client.send(:connection_key, URI("https://api.workos.com"), 30)
    conn = FakeConnection.new
    Thread.current[:workos_connections] = {key => conn}

    client.send(:evict_connection, "https://api.workos.com")

    assert_empty Thread.current[:workos_connections]
    assert conn.finished
  end

  def test_requests_through_a_proxied_client_never_log_proxy_credentials
    io = StringIO.new
    client = WorkOS::BaseClient.new(
      api_key: "sk_test_123",
      proxy: "http://user:s3cret@proxy.example.com:8080",
      logger: Logger.new(io),
      log_level: :debug,
      max_retries: 0
    )
    stub_request(:get, "https://api.workos.com/organizations").to_return(status: 500, body: "{}")

    assert_raises(WorkOS::APIError) { client.request(method: :get, path: "/organizations") }

    refute_empty io.string
    refute_includes io.string, "s3cret"
    refute_includes io.string, "proxy.example.com"
  end

  # A reserved name that never resolves. The tests below reach it only through
  # a local proxy, so a request that skipped the proxy fails instead of
  # leaving the machine.
  UNREACHABLE_BASE_URL = "https://workos.invalid"

  # A proxy that answers CONNECT with an error never tunnels the request, and
  # Net::HTTP raises while opening the connection. Callers must get the
  # documented transport error, not a raw Net::HTTP exception.
  def test_proxy_rejecting_connect_raises_api_connection_error_without_retrying
    with_rejecting_proxy("407 Proxy Authentication Required") do |proxy_url, connects|
      io = StringIO.new
      client = WorkOS::BaseClient.new(
        api_key: "sk_test_123",
        base_url: UNREACHABLE_BASE_URL,
        proxy: proxy_url,
        logger: Logger.new(io),
        log_level: :debug,
        timeout: 5,
        max_retries: 2
      )

      error = assert_raises(WorkOS::APIConnectionError) { client.request(method: :get, path: "/organizations") }

      assert_equal 'Proxy rejected the connection: 407 "Proxy Authentication Required"', error.message
      assert_kind_of Net::HTTPClientException, error.cause
      assert_equal ["CONNECT workos.invalid:443 HTTP/1.1\r\n"], connects, "bad proxy credentials must not be retried"
      assert_includes io.string, "Proxy rejected the connection"
      refute_includes io.string, "s3cret"
      assert_empty client.send(:thread_connections)
    end
  end

  def test_proxy_503_on_connect_is_retried_before_raising
    with_rejecting_proxy("503 Service Unavailable") do |proxy_url, connects|
      client = WorkOS::BaseClient.new(api_key: "sk_test_123", base_url: UNREACHABLE_BASE_URL, proxy: proxy_url, timeout: 5, max_retries: 2)
      client.singleton_class.define_method(:sleep) { |_duration| nil }

      error = assert_raises(WorkOS::APIConnectionError) { client.request(method: :get, path: "/organizations") }

      assert_equal 'Proxy rejected the connection: 503 "Service Unavailable"', error.message
      assert_equal 3, connects.size
    end
  end

  def test_proxy_retry_after_on_connect_is_honored
    with_rejecting_proxy("429 Too Many Requests", "Retry-After" => "7") do |proxy_url, connects|
      sleeps = []
      client = WorkOS::BaseClient.new(api_key: "sk_test_123", base_url: UNREACHABLE_BASE_URL, proxy: proxy_url, timeout: 5, max_retries: 1)
      client.singleton_class.define_method(:sleep) { |duration| sleeps << duration }

      assert_raises(WorkOS::APIConnectionError) { client.request(method: :get, path: "/organizations") }

      assert_equal [7.0], sleeps
      assert_equal 2, connects.size
    end
  end

  # Clients that take their proxy from the environment, which is every client
  # that does not pass the proxy option, go through the same code.
  def test_env_proxy_rejecting_connect_raises_api_connection_error
    with_rejecting_proxy("403 Forbidden") do |proxy_url, connects|
      with_env("http_proxy" => proxy_url, "no_proxy" => nil, "NO_PROXY" => nil) do
        client = WorkOS::BaseClient.new(api_key: "sk_test_123", base_url: UNREACHABLE_BASE_URL, timeout: 5, max_retries: 0)

        error = assert_raises(WorkOS::APIConnectionError) { client.request(method: :get, path: "/organizations") }

        assert_equal 'Proxy rejected the connection: 403 "Forbidden"', error.message
        assert_equal 1, connects.size
      end
    end
  end

  # Runs a local stand-in for an HTTP proxy that answers every CONNECT with
  # +status+ and never tunnels anything. Yields the proxy's URL and the list
  # of CONNECT request lines it has received. WebMock is switched off so that
  # Net::HTTP really opens the socket.
  def with_rejecting_proxy(status, headers = {})
    WebMock.disable!
    server = TCPServer.new("127.0.0.1", 0)
    connects = []
    extra_headers = headers.map { |name, value| "#{name}: #{value}\r\n" }.join
    server_thread = Thread.new do
      loop do
        socket = server.accept
        connects << read_http_request(socket)
        socket.write("HTTP/1.1 #{status}\r\n#{extra_headers}Content-Length: 0\r\n\r\n")
        socket.close
      end
    end

    yield "http://user:s3cret@127.0.0.1:#{server.addr[1]}", connects
  ensure
    server_thread&.kill
    server&.close
    WebMock.enable!
  end

  # Stubs Net::HTTP#start to avoid real TCP+TLS connections while still
  # marking the connection as started, so pooled reuse is exercised.
  def with_stubbed_start
    original_start = Net::HTTP.instance_method(:start)
    Net::HTTP.define_method(:start) do
      @started = true
      self
    end
    yield
  ensure
    Net::HTTP.define_method(:start, original_start)
  end

  def with_env(overrides)
    saved = overrides.to_h { |name, _| [name, ENV[name]] }
    overrides.each { |name, value| ENV[name] = value }
    yield
  ensure
    saved.each { |name, value| ENV[name] = value }
  end

  # Exercises the connection_for path (not just the storage helper):
  # each thread must open and cache its *own* Net::HTTP connection rather
  # than reusing one established on another thread.
  #
  # Net::HTTP#start is stubbed to avoid real TCP+TLS connections.
  def test_connection_for_opens_a_distinct_connection_per_thread
    original_start = Net::HTTP.instance_method(:start)
    Net::HTTP.define_method(:start) { self }

    parent_conn = @client.send(:connection_for, "https://api.workos.com", 30)

    worker_conns = Array.new(4) do
      Thread.new { @client.send(:connection_for, "https://api.workos.com", 30).object_id }
    end.map(&:value)

    refute_includes worker_conns, parent_conn.object_id,
      "a worker thread reused a connection opened on another thread"
    assert_equal worker_conns.length, worker_conns.uniq.length,
      "worker threads must each get a distinct connection"
  ensure
    Net::HTTP.define_method(:start, original_start)
  end

  def test_redact_path_strips_invitation_token_segment
    redacted = @client.send(:redact_path, "/user_management/invitations/by_token/invtoken_secret123")
    assert_equal "/user_management/invitations/by_token/[REDACTED]", redacted
  end

  def test_redact_path_strips_magic_auth_token_segment
    redacted = @client.send(:redact_path, "/user_management/magic_auth/magic_secret/extra")
    assert_equal "/user_management/magic_auth/[REDACTED]/[REDACTED]", redacted
  end

  def test_redact_path_preserves_non_token_paths
    assert_equal "/organizations/org_123", @client.send(:redact_path, "/organizations/org_123")
  end

  def test_redact_path_preserves_query_string
    redacted = @client.send(:redact_path, "/user_management/invitations/by_token/secret?foo=bar")
    assert_equal "/user_management/invitations/by_token/[REDACTED]?foo=bar", redacted
  end

  def test_redact_path_handles_nil_and_empty
    assert_nil @client.send(:redact_path, nil)
    assert_equal "", @client.send(:redact_path, "")
  end

  def test_redact_path_scrubs_sensitive_query_params
    redacted = @client.send(:redact_path, "/user_management/sessions/logout?session_id=ses_abc123&return_to=https://app.example.com")
    assert_equal "/user_management/sessions/logout?session_id=[REDACTED]&return_to=https://app.example.com", redacted
  end

  def test_redact_path_scrubs_authorize_code_query_param
    redacted = @client.send(:redact_path, "/user_management/authorize?client_id=client_1&code=auth_code_secret&state=xyz")
    assert_equal "/user_management/authorize?client_id=client_1&code=[REDACTED]&state=xyz", redacted
  end

  def test_redact_path_leaves_non_sensitive_query_params_untouched
    redacted = @client.send(:redact_path, "/user_management/users?limit=10&order=desc")
    assert_equal "/user_management/users?limit=10&order=desc", redacted
  end

  def test_redact_path_scrubs_query_alongside_path_segment_redaction
    redacted = @client.send(:redact_path, "/user_management/magic_auth/magic_secret?token=qs_token")
    assert_equal "/user_management/magic_auth/[REDACTED]?token=[REDACTED]", redacted
  end
end
