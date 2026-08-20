# frozen_string_literal: true

require "test_helper"

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
    # Close any open connections and clear the fiber-local cache to avoid
    # leaking pooled connections between tests.
    @client.shutdown
    Fiber[:workos_connections] = nil
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

  def test_retry_path_generates_idempotency_key_for_mutating_requests
    stub_request(:post, "https://api.workos.com/widgets")
      .to_return({status: 500, body: '{"message":"retry"}'}, {status: 200, body: "{}"})

    @client.singleton_class.define_method(:sleep) { |_duration| nil }
    @client.request(method: :post, path: "/widgets", body: {name: "widget"})

    assert_requested(:post, "https://api.workos.com/widgets", times: 2)
    assert_requested(:post, "https://api.workos.com/widgets", headers: {"Idempotency-Key" => /.+/}, times: 1)
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

  def read_http_request(socket)
    socket.gets # request line
    loop do
      line = socket.gets
      break if line.nil? || line == "\r\n"
    end
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
end
