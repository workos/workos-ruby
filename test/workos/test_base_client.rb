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

  def setup
    @client = WorkOS::BaseClient.new(api_key: "sk_test_123", max_retries: 1)
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
end
