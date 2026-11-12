# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained: workload identity conformance cases
# WIF-01 to WIF-24 (docs: conformance-cases.md in the WIF plan), plus the
# Ruby-specific behavior around them.

require "test_helper"
require "logger"
require "open3"
require "pp"
require "stringio"
require "tempfile"
require "timeout"

class WorkloadIdentityTest < Minitest::Test
  API = "https://api.workos.com"
  TOKEN_URL = "https://auth.workos.test/oauth2/token"
  CLIENT_ID = "client_wif_test"
  ENVIRONMENT_ID = "environment_wif_test"
  WIF_ENV = %w[WORKOS_CLIENT_ID WORKOS_WIF_TOKEN_URL WORKOS_WIF_SCOPE WORKOS_ENVIRONMENT_ID WORKOS_API_KEY].freeze
  EXCHANGE_THREAD = "workos-workload-identity-exchange"

  class FakeClock
    attr_accessor :now

    def initialize
      @now = 0.0
    end

    def call
      @now
    end
  end

  def setup
    @lock = Mutex.new
    @clock = FakeClock.new
    @sleeps = []
    @provider_calls = 0
    @issued = 0
    @token_requests = []
    @api_requests = []
    @clients = []
    @saved_env = WIF_ENV.to_h { |name| [name, ENV[name]] }
    WIF_ENV.each { |name| ENV.delete(name) }
  end

  def teardown
    super
    Thread.list.select { |thread| thread.name == EXCHANGE_THREAD }.each { |thread| thread.join(5) }
    @clients.each(&:shutdown)
    Thread.current[:workos_connections] = nil
    @saved_env.each { |name, value| value.nil? ? ENV.delete(name) : ENV[name] = value }
  end

  # -- Mocks ---------------------------------------------------------------

  # The mock token endpoint. With no block every POST succeeds with the next
  # access token. A block receives the 1-based POST count and the request and
  # returns a response hash, or raises to simulate a transport failure.
  def stub_token_endpoint(url: TOKEN_URL, expires_in: 300, &script)
    stub_request(:post, url).to_return do |request|
      count = @lock.synchronize do
        @token_requests << request
        @token_requests.size
      end
      script ? script.call(count, request) : issue_token(expires_in: expires_in)
    end
  end

  def issue_token(expires_in: 300, access_token: nil)
    number = @lock.synchronize { @issued += 1 }
    body = {access_token: access_token || "access-#{number}", token_type: "Bearer"}
    body[:expires_in] = expires_in unless expires_in.nil?
    {status: 200, headers: {"Content-Type" => "application/json"}, body: JSON.generate(body)}
  end

  def oauth_error(code, description = "rejected by the mock")
    {status: 400, headers: {"Content-Type" => "application/json"}, body: JSON.generate(error: code, error_description: description)}
  end

  # The mock WorkOS API. Same contract as stub_token_endpoint.
  def stub_api(method = :get, path = "/widgets", &script)
    stub_request(method, "#{API}#{path}").to_return do |request|
      count = @lock.synchronize do
        @api_requests << request
        @api_requests.size
      end
      script ? script.call(count, request) : {status: 200, body: "{}"}
    end
  end

  def unauthorized
    {status: 401, body: '{"message":"Unauthorized"}'}
  end

  def reset_mocks
    Thread.list.select { |thread| thread.name == EXCHANGE_THREAD }.each { |thread| thread.join(5) }
    WebMock.reset!
    @lock.synchronize do
      @token_requests = []
      @api_requests = []
      @issued = 0
      @provider_calls = 0
      @sleeps = []
    end
  end

  # -- Subjects ------------------------------------------------------------

  def counting_provider(*assertions)
    lambda do
      call = @lock.synchronize { @provider_calls += 1 }
      assertions[[call, assertions.size].min - 1]
    end
  end

  def credentials(**overrides)
    WorkOS::WorkloadIdentity::Credentials.new(
      client_id: CLIENT_ID,
      token_url: TOKEN_URL,
      environment_id: ENVIRONMENT_ID,
      identity_token_provider: counting_provider("assertion-1"),
      clock: @clock,
      sleeper: ->(seconds) { @lock.synchronize { @sleeps << seconds } },
      **overrides
    )
  end

  def client_for(creds = credentials, **options)
    track(WorkOS::Client.new(credentials: creds, **options))
  end

  def track(client)
    # Transport-retry backoff is not under test; keep the suite fast.
    client.singleton_class.define_method(:sleep) { |_duration| nil }
    @clients << client
    client
  end

  def get_widgets(client, **request_options)
    client.request(method: :get, path: "/widgets", request_options: request_options)
  end

  def form_of(request)
    URI.decode_www_form(request.body).to_h
  end

  def header(request, name)
    request.headers.find { |key, _value| key.casecmp?(name) }&.last
  end

  def bearers
    @api_requests.map { |request| header(request, "Authorization") }
  end

  def with_env(values)
    saved = values.to_h { |name, _value| [name, ENV[name]] }
    values.each { |name, value| value.nil? ? ENV.delete(name) : ENV[name] = value }
    yield
  ensure
    saved.each { |name, value| value.nil? ? ENV.delete(name) : ENV[name] = value }
  end

  def wait_until(seconds = 5)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + seconds
    until yield
      flunk "condition not reached within #{seconds}s" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
      sleep 0.005
    end
  end

  def with_exchange_deadline(seconds)
    namespace = WorkOS::WorkloadIdentity
    original = namespace::EXCHANGE_DEADLINE
    namespace.send(:remove_const, :EXCHANGE_DEADLINE)
    namespace.const_set(:EXCHANGE_DEADLINE, seconds)
    yield
  ensure
    namespace.send(:remove_const, :EXCHANGE_DEADLINE)
    namespace.const_set(:EXCHANGE_DEADLINE, original)
  end

  # Every string a user or a log aggregator could see for this error.
  def renderings(error)
    chain = []
    while error
      chain << error
      error = error.cause
    end
    chain.flat_map { |e| [e.message, e.to_s, e.inspect, e.full_message(highlight: false), e.detailed_message] }
  end

  # -- Conformance: exchange and cache ---------------------------------------

  def test_WIF_01_first_request_sends_one_exchange_post_with_the_right_shape
    stub_token_endpoint
    stub_api

    get_widgets(client_for)

    assert_equal 1, @token_requests.size
    post = @token_requests.first
    assert_equal "application/x-www-form-urlencoded", header(post, "Content-Type")
    assert_nil header(post, "Authorization")
    assert_equal(
      {
        "grant_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion" => "assertion-1",
        "client_id" => "client_wif_test",
        "resource" => "https://api.workos.com"
      },
      form_of(post)
    )
    refute_includes post.body, "client_secret"
    refute_includes post.body, "scope"

    get_widgets(client_for(credentials(scope: "organizations:write")))

    assert_equal 2, @token_requests.size
    scoped = @token_requests.last
    assert_equal "organizations:write", form_of(scoped)["scope"]
    refute form_of(scoped).key?("client_secret")
    assert_nil header(scoped, "Authorization")
  end

  def test_WIF_02_api_request_carries_the_access_token_and_environment_header
    stub_token_endpoint
    stub_api

    get_widgets(client_for)

    request = @api_requests.first
    assert_equal "Bearer access-1", header(request, "Authorization")
    assert_equal "environment_wif_test", header(request, "x-url-environment-id")
  end

  def test_WIF_03_second_request_within_the_lifetime_reuses_the_cached_token
    stub_token_endpoint(expires_in: 300)
    stub_api
    client = client_for

    2.times { get_widgets(client) }

    assert_equal 1, @token_requests.size
    assert_equal ["Bearer access-1", "Bearer access-1"], bearers
  end

  def test_WIF_04_token_with_300s_lifetime_refreshes_when_less_than_60s_remain
    stub_token_endpoint(expires_in: 300)
    stub_api
    client = client_for

    get_widgets(client)
    @clock.now = 239
    get_widgets(client)
    assert_equal 1, @token_requests.size

    @clock.now = 241
    get_widgets(client)
    assert_equal 2, @token_requests.size
    assert_equal "Bearer access-2", bearers.last
  end

  def test_WIF_05_token_with_100s_lifetime_refreshes_at_20_percent_not_60s
    stub_token_endpoint(expires_in: 100)
    stub_api
    client = client_for

    get_widgets(client)
    @clock.now = 79
    get_widgets(client)
    assert_equal 1, @token_requests.size

    @clock.now = 81
    get_widgets(client)
    assert_equal 2, @token_requests.size
  end

  def test_WIF_06_response_without_expires_in_is_treated_as_300s
    stub_token_endpoint(expires_in: nil)
    stub_api
    client = client_for

    get_widgets(client)
    refute_includes @token_requests.first.body, "expires_in"
    @clock.now = 239
    get_widgets(client)
    assert_equal 1, @token_requests.size

    @clock.now = 241
    get_widgets(client)
    assert_equal 2, @token_requests.size
  end

  def test_WIF_07_two_credentials_instances_never_share_a_cached_token
    stub_token_endpoint
    stub_api

    get_widgets(client_for(credentials))
    get_widgets(client_for(credentials))

    assert_equal 2, @token_requests.size
    assert_equal ["Bearer access-1", "Bearer access-2"], bearers
  end

  def test_WIF_08_twenty_concurrent_first_requests_produce_exactly_one_exchange
    release = Queue.new
    stub_token_endpoint do
      release.pop
      issue_token
    end
    stub_api
    client = client_for

    callers = Array.new(20) { Thread.new { get_widgets(client) } }
    # The endpoint holds its response until every caller is parked on the
    # one shared exchange.
    wait_until { @token_requests.size == 1 && callers.all? { |thread| thread.status == "sleep" } }
    release << :respond
    callers.each { |thread| thread.join(10) }

    assert(callers.all? { |thread| thread.value.is_a?(Net::HTTPSuccess) })
    assert_equal 1, @token_requests.size
    assert_equal 1, @provider_calls
    assert_equal ["Bearer access-1"] * 20, bearers
  end

  # -- Conformance: 401 recovery -------------------------------------------

  def test_WIF_09_a_401_invalidates_that_generation_exchanges_again_and_retries_once
    stub_token_endpoint
    stub_api { |count| (count == 1) ? unauthorized : {status: 200, body: "{}"} }

    response = get_widgets(client_for)

    assert_kind_of Net::HTTPSuccess, response
    assert_equal 2, @token_requests.size
    assert_equal ["Bearer access-1", "Bearer access-2"], bearers
  end

  def test_WIF_10_a_second_401_after_recovery_is_returned_to_the_caller
    stub_token_endpoint
    stub_api { unauthorized }

    assert_raises(WorkOS::AuthenticationError) { get_widgets(client_for) }

    assert_equal 2, @token_requests.size
    assert_equal 2, @api_requests.size
  end

  def test_WIF_11_a_late_401_for_an_old_generation_does_not_discard_a_newer_token
    stub_token_endpoint
    stub_api
    creds = credentials

    first = creds.resolve
    assert_equal "Bearer access-1", first.headers["Authorization"]
    creds.invalidate(first.generation)
    second = creds.resolve
    assert_equal "Bearer access-2", second.headers["Authorization"]
    refute_equal first.generation, second.generation

    # The late 401: it names the old generation.
    creds.invalidate(first.generation)

    assert_equal second.generation, creds.resolve.generation
    get_widgets(client_for(creds))
    assert_equal 2, @token_requests.size
    assert_equal ["Bearer access-2"], bearers
  end

  def test_WIF_12_transport_retries_do_not_reset_the_single_401_recovery
    stub_token_endpoint
    stub_api do |count|
      case count
      when 1, 3 then unauthorized
      when 2 then {status: 503, headers: {"Retry-After" => "0"}, body: '{"message":"unavailable"}'}
      else {status: 200, body: "{}"}
      end
    end

    assert_raises(WorkOS::AuthenticationError) { get_widgets(client_for) }

    assert_equal 2, @token_requests.size
    assert_equal 3, @api_requests.size
    assert_equal ["Bearer access-1", "Bearer access-2", "Bearer access-2"], bearers
  end

  def test_WIF_13_the_401_retry_sends_the_same_body_and_idempotency_key
    stub_token_endpoint
    stub_api(:post) { |count| (count == 1) ? unauthorized : {status: 200, body: "{}"} }

    client_for.request(method: :post, path: "/widgets", body: {name: "widget", tags: ["a", "b"]})

    assert_equal 2, @api_requests.size
    first, second = @api_requests
    assert_equal first.body, second.body
    assert_equal '{"name":"widget","tags":["a","b"]}', second.body
    key = header(first, "Idempotency-Key")
    refute_nil key
    refute_empty key
    assert_equal key, header(second, "Idempotency-Key")
    assert_equal ["Bearer access-1", "Bearer access-2"], bearers
  end

  # -- Conformance: exchange retries and errors ------------------------------

  def test_WIF_14_exchange_retries_503_then_429_and_asks_the_provider_each_time
    stub_token_endpoint do |count|
      case count
      when 1 then {status: 503, body: "unavailable"}
      when 2 then {status: 429, headers: {"Retry-After" => "0"}, body: "slow down"}
      else issue_token
      end
    end
    stub_api

    get_widgets(client_for)

    assert_equal 3, @token_requests.size
    assert_equal 3, @provider_calls
    assert_equal ["Bearer access-1"], bearers
  end

  def test_WIF_14_exchange_retries_a_connection_failure
    stub_token_endpoint do |count|
      raise Errno::ECONNREFUSED if count == 1

      issue_token
    end
    stub_api

    get_widgets(client_for)

    assert_equal 2, @provider_calls
    assert_equal ["Bearer access-1"], bearers
  end

  def test_WIF_14_exchange_retries_a_failing_provider
    stub_token_endpoint
    stub_api
    provider = lambda do
      call = @lock.synchronize { @provider_calls += 1 }
      raise "metadata server not ready" if call == 1

      "assertion-#{call}"
    end

    get_widgets(client_for(credentials(identity_token_provider: provider)))

    assert_equal 2, @provider_calls
    assert_equal 1, @token_requests.size
    assert_equal "assertion-2", form_of(@token_requests.first)["assertion"]
    assert_equal ["Bearer access-1"], bearers
  end

  def test_WIF_14_exchange_honors_retry_after
    stub_token_endpoint do |count|
      (count == 1) ? {status: 429, headers: {"Retry-After" => "1"}, body: ""} : issue_token
    end
    stub_api

    get_widgets(client_for)

    assert_equal 2, @token_requests.size
    assert_equal 1, @sleeps.size
    assert_operator @sleeps.first, :>=, 1
  end

  def test_WIF_15_an_oauth_error_is_not_retried_and_surfaces_as_a_typed_error
    %w[invalid_grant invalid_target invalid_client unauthorized_client invalid_scope invalid_request].each do |code|
      reset_mocks
      stub_token_endpoint { oauth_error(code, "the server said #{code}") }
      stub_api

      error = assert_raises(WorkOS::WorkloadIdentityError) { get_widgets(client_for) }

      assert_equal code, error.code
      assert_equal "the server said #{code}", error.description
      refute_empty error.hint
      refute_equal WorkOS::WorkloadIdentityError::DEFAULT_HINT, error.hint
      assert_equal "#{code}: #{error.hint} the server said #{code}", error.message
      assert_equal 1, @token_requests.size, "#{code} was retried"
      assert_empty @api_requests
    end
  end

  def test_WIF_16_after_a_failed_exchange_the_next_request_exchanges_afresh
    stub_token_endpoint { |count| (count == 1) ? oauth_error("invalid_grant") : issue_token }
    stub_api
    client = client_for

    assert_raises(WorkOS::WorkloadIdentityError) { get_widgets(client) }
    response = get_widgets(client)

    assert_kind_of Net::HTTPSuccess, response
    assert_equal ["Bearer access-1"], bearers
    assert_equal 2, @token_requests.size
  end

  def test_WIF_17_neither_token_appears_in_any_error_or_log_line
    assertion = "SECRET-ASSERTION-VALUE"
    access_token = "SECRET-ACCESS-VALUE"
    log = StringIO.new
    logger = Logger.new(log)
    logger.level = Logger::DEBUG
    errors = []
    build = lambda do |**overrides|
      client_for(
        credentials(identity_token_provider: -> { assertion }, **overrides),
        logger: logger, log_level: :debug
      )
    end

    # An invalid_grant exchange, from a server that echoes the assertion.
    stub_token_endpoint { oauth_error("invalid_grant", "assertion #{assertion} matched no trust rule") }
    stub_api
    errors << assert_raises(WorkOS::WorkloadIdentityError) { get_widgets(build.call) }

    # A 500 from the token endpoint until retries run out.
    reset_mocks
    stub_token_endpoint { {status: 500, body: JSON.generate(error: "server_error", error_description: "boom #{assertion}")} }
    stub_api
    errors << assert_raises(WorkOS::WorkloadIdentityError) { get_widgets(build.call) }
    assert_equal 1 + WorkOS::BaseClient::DEFAULT_MAX_RETRIES, @token_requests.size

    # A provider that raises.
    reset_mocks
    stub_token_endpoint
    stub_api
    errors << assert_raises(WorkOS::WorkloadIdentityError) do
      get_widgets(build.call(identity_token_provider: -> { raise IOError, "no token source" }))
    end
    assert_equal "provider_failed", errors.last.code

    # A second 401 from the API, with a real access token in play.
    reset_mocks
    stub_token_endpoint { issue_token(access_token: access_token) }
    stub_api { unauthorized }
    creds = credentials(identity_token_provider: -> { assertion })
    errors << assert_raises(WorkOS::AuthenticationError) do
      get_widgets(client_for(creds, logger: logger, log_level: :debug))
    end
    assert_equal ["Bearer #{access_token}"] * 2, bearers

    assert_equal 4, errors.size
    snapshot = creds.resolve
    seen = errors.flat_map { |error| renderings(error) } +
      [log.string, creds.inspect, PP.pp(creds, +""), snapshot.inspect, snapshot.to_s, PP.pp(snapshot, +"")]
    refute_empty log.string
    seen.each do |text|
      refute_includes text, assertion
      refute_includes text, access_token
    end
  end

  def test_WIF_18_the_exchange_does_not_follow_redirects
    elsewhere = "https://elsewhere.workos.test/oauth2/token"
    stub_token_endpoint { {status: 307, headers: {"Location" => elsewhere}, body: ""} }
    stub_request(:any, elsewhere).to_return(status: 200, body: JSON.generate(access_token: "access-stolen", expires_in: 300))
    stub_api

    error = assert_raises(WorkOS::WorkloadIdentityError) { get_widgets(client_for) }

    assert_equal "exchange_failed", error.code
    assert_equal 1, @token_requests.size
    assert_not_requested :any, elsewhere
    assert_empty @api_requests
  end

  # -- Conformance: precedence ---------------------------------------------

  def test_WIF_19_an_api_key_together_with_credentials_is_a_configuration_error
    stub_token_endpoint
    stub_api

    error = assert_raises(ArgumentError) do
      WorkOS::Client.new(api_key: "sk_test_123", credentials: credentials)
    end

    assert_equal "api_key and credentials were both given; pass one or the other", error.message
    assert_empty @token_requests
    assert_empty @api_requests
    assert_not_requested :any, /.*/
  end

  def test_WIF_20_credentials_win_over_the_environment_key_and_never_fall_back_to_it
    with_env("WORKOS_API_KEY" => "sk_test_env") do
      # (a) Valid credentials.
      stub_token_endpoint
      stub_api
      get_widgets(client_for)
      assert_equal ["Bearer access-1"], bearers

      # (b) No token URL, explicitly or in the environment.
      error = assert_raises(WorkOS::WorkloadIdentityError) { credentials(token_url: nil) }
      assert_equal "invalid_configuration", error.code
      assert_equal "token_url is required (or set WORKOS_WIF_TOKEN_URL)", error.description

      # (c) Valid credentials whose exchange fails.
      reset_mocks
      stub_token_endpoint { oauth_error("invalid_client") }
      stub_api
      failed = assert_raises(WorkOS::WorkloadIdentityError) { get_widgets(client_for) }
      assert_equal "invalid_client", failed.code
      assert_empty @api_requests

      assert_not_requested :any, /.*/, headers: {"Authorization" => "Bearer sk_test_env"}
      (@token_requests + @api_requests).each { |request| refute_includes request.headers.values.join(" "), "sk_test_env" }
    end
  end

  def test_WIF_24_static_api_key_clients_are_unchanged
    stub_token_endpoint
    stub_api { |count| (count == 1) ? {status: 200, body: "{}"} : unauthorized }
    client = track(WorkOS::Client.new(api_key: "sk_test_123"))

    get_widgets(client)

    request = @api_requests.first
    assert_equal "Bearer sk_test_123", header(request, "Authorization")
    assert_nil header(request, "x-url-environment-id")
    # The whole header set an API-key request has always sent.
    assert_equal(
      {
        "Accept" => "*/*",
        "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
        "Authorization" => "Bearer sk_test_123",
        "User-Agent" => WorkOS::BaseClient::USER_AGENT
      },
      request.headers.to_h
    )

    assert_raises(WorkOS::AuthenticationError) { get_widgets(client) }

    assert_equal 2, @api_requests.size, "the 401 was retried"
    assert_empty @token_requests
    refute client.credentials.resolve.recoverable
    assert_equal "sk_test_123", client.api_key
  end

  # -- Conformance: custom providers -----------------------------------------

  def test_WIF_21_token_file_is_read_again_on_every_exchange
    stub_token_endpoint(expires_in: 300)
    stub_api
    Tempfile.create("workos-wif-token") do |file|
      file.write("assertion-1\n")
      file.flush
      client = client_for(credentials(identity_token_provider: WorkOS::WorkloadIdentity.token_file(file.path)))

      get_widgets(client)
      File.write(file.path, "  assertion-2\n\n")
      @clock.now = 300
      get_widgets(client)
    end

    assert_equal %w[assertion-1 assertion-2], @token_requests.map { |request| form_of(request)["assertion"] }
    assert_equal ["Bearer access-1", "Bearer access-2"], bearers
  end

  def test_WIF_22_token_env_and_callback_supply_the_assertion
    stub_token_endpoint
    stub_api

    with_env("MY_JWT" => "assertion-env") do
      get_widgets(client_for(credentials(identity_token_provider: WorkOS::WorkloadIdentity.token_env("MY_JWT"))))
    end
    get_widgets(client_for(credentials(identity_token_provider: -> { "assertion-cb" })))

    assert_equal %w[assertion-env assertion-cb], @token_requests.map { |request| form_of(request)["assertion"] }
  end

  def test_WIF_22_omitted_fields_default_from_the_environment_and_explicit_values_win
    env_token_url = "https://env.workos.test/oauth2/token"
    environment = {
      "WORKOS_CLIENT_ID" => "client_env",
      "WORKOS_WIF_TOKEN_URL" => env_token_url,
      "WORKOS_WIF_SCOPE" => "scope_env",
      "WORKOS_ENVIRONMENT_ID" => "environment_env"
    }
    stub_token_endpoint(url: env_token_url)
    stub_api

    with_env(environment) do
      # (c) Only a provider is passed.
      from_env = WorkOS::WorkloadIdentity::Credentials.new(identity_token_provider: -> { "assertion-1" })
      get_widgets(client_for(from_env))

      form = form_of(@token_requests.last)
      assert_equal "client_env", form["client_id"]
      assert_equal "scope_env", form["scope"]
      assert_equal "https://api.workos.com", form["resource"]
      assert_equal "environment_env", header(@api_requests.last, "x-url-environment-id")

      # (d) Same environment, explicit values.
      explicit = WorkOS::WorkloadIdentity::Credentials.new(
        identity_token_provider: -> { "assertion-1" },
        client_id: "client_explicit",
        scope: "scope_explicit",
        environment_id: "environment_explicit"
      )
      get_widgets(client_for(explicit))

      form = form_of(@token_requests.last)
      assert_equal "client_explicit", form["client_id"]
      assert_equal "scope_explicit", form["scope"]
      assert_equal "environment_explicit", header(@api_requests.last, "x-url-environment-id")
      assert_equal 2, @token_requests.size
    end
  end

  # -- Conformance: a caller that gives up -----------------------------------

  # Ruby has no cancellation primitive. The case here: caller A's request
  # times out during a slow exchange; caller B then succeeds, and nothing A
  # left behind reaches B.
  def test_WIF_23_a_caller_that_times_out_does_not_cancel_or_poison_the_shared_exchange
    release = Queue.new
    stub_token_endpoint do
      release.pop
      issue_token
    end
    stub_api
    client = client_for

    error = assert_raises(WorkOS::APIConnectionError) { get_widgets(client, timeout: 0.05) }
    assert_match(/Timed out/, error.message)
    assert_empty @api_requests

    # The endpoint is fast from here on. The exchange A gave up on is still
    # the one in flight; B gets its token.
    release << :respond
    response = get_widgets(client)

    assert_kind_of Net::HTTPSuccess, response
    assert_equal ["Bearer access-1"], bearers
    assert_equal 1, @token_requests.size
    assert_equal 1, @provider_calls
  end

  def test_WIF_23_a_caller_interrupted_mid_wait_does_not_cancel_or_poison_the_shared_exchange
    release = Queue.new
    stub_token_endpoint do
      release.pop
      issue_token
    end
    stub_api
    client = client_for

    # An application-level timeout unwinds A from outside while it waits.
    assert_raises(Timeout::Error) { Timeout.timeout(0.05) { get_widgets(client) } }
    assert_empty @api_requests

    release << :respond
    2.times { assert_kind_of Net::HTTPSuccess, get_widgets(client) }

    assert_equal ["Bearer access-1", "Bearer access-1"], bearers
    assert_equal 1, @token_requests.size
  end

  # -- Ruby-specific behavior ------------------------------------------------

  def test_per_request_api_key_keeps_precedence_and_is_not_recoverable
    stub_token_endpoint
    stub_api { unauthorized }

    assert_raises(WorkOS::AuthenticationError) { get_widgets(client_for, api_key: "sk_override") }

    assert_equal ["Bearer sk_override"], bearers
    assert_nil header(@api_requests.first, "x-url-environment-id")
    assert_empty @token_requests
  end

  def test_caller_supplied_authorization_header_keeps_precedence
    stub_token_endpoint
    stub_api
    extra = {extra_headers: {"authorization" => "Bearer user_token"}}

    get_widgets(client_for, **extra)
    get_widgets(track(WorkOS::Client.new(api_key: "sk_test_123")), **extra)

    assert_equal ["Bearer user_token", "Bearer user_token"], bearers
    assert_empty @token_requests
  end

  def test_an_api_key_request_edited_between_build_and_execute_is_sent_as_edited
    stub_api
    client = track(WorkOS::Client.new(api_key: "sk_test_123"))
    request = client.get_request(path: "/widgets", auth: true)
    request["Authorization"] = "Bearer edited_by_caller"

    client.execute_request(request: request)

    assert_equal ["Bearer edited_by_caller"], bearers
  end

  def test_unauthenticated_requests_do_not_exchange
    stub_token_endpoint
    stub_api
    client = client_for

    client.execute_request(request: client.get_request(path: "/widgets", auth: false))

    assert_nil header(@api_requests.first, "Authorization")
    assert_nil header(@api_requests.first, "x-url-environment-id")
    assert_empty @token_requests
  end

  def test_building_a_request_does_not_exchange
    stub_token_endpoint
    client = client_for

    request = client.get_request(path: "/widgets", auth: true)

    assert_nil request["Authorization"]
    assert_empty @token_requests
    assert_equal "Bearer sk_test_123", WorkOS::Client.new(api_key: "sk_test_123").get_request(path: "/widgets", auth: true)["Authorization"]
  end

  def test_a_401_on_a_streamed_body_is_returned_without_recovery
    stub_token_endpoint
    stub_api(:post) { unauthorized }
    client = client_for
    request = client.post_request(path: "/widgets", auth: true, body: nil)
    request.body = nil
    request.body_stream = StringIO.new("{}")
    request["Content-Length"] = "2"

    assert_raises(WorkOS::AuthenticationError) { client.execute_request(request: request) }

    assert_equal 1, @api_requests.size
    assert_equal 1, @token_requests.size
  end

  def test_credentials_that_do_not_quack_are_rejected
    assert_raises(ArgumentError) { WorkOS::Client.new(credentials: Object.new) }
  end

  def test_configuration_passes_credentials_to_the_global_client
    stub_token_endpoint
    stub_api
    saved_key = WorkOS.configuration.api_key
    WorkOS.reset_client
    WorkOS.configure do |config|
      config.api_key = nil
      config.credentials = credentials
    end

    get_widgets(track(WorkOS.client))

    assert_equal ["Bearer access-1"], bearers
  ensure
    WorkOS.reset_client
    WorkOS.configuration.credentials = nil
    WorkOS.configuration.api_key = saved_key
  end

  def test_missing_settings_are_configuration_errors_naming_the_field_and_variable
    {
      client_id: "client_id is required (or set WORKOS_CLIENT_ID)",
      token_url: "token_url is required (or set WORKOS_WIF_TOKEN_URL)",
      environment_id: "environment_id is required (or set WORKOS_ENVIRONMENT_ID)",
      identity_token_provider: "identity_token_provider is required and must respond to call"
    }.each do |field, description|
      error = assert_raises(WorkOS::WorkloadIdentityError) { credentials(field => nil) }

      assert_equal "invalid_configuration", error.code
      assert_equal description, error.description
      assert_equal "invalid_configuration: Workload identity credentials are missing a required setting. #{description}", error.message
    end

    error = assert_raises(WorkOS::WorkloadIdentityError) { credentials(token_url: "not a url") }
    assert_equal "token_url must be an http or https URL", error.description
  end

  def test_explicit_empty_scope_beats_the_environment_scope
    stub_token_endpoint
    stub_api

    with_env("WORKOS_WIF_SCOPE" => "scope_env") do
      get_widgets(client_for(credentials(scope: "")))
    end

    refute form_of(@token_requests.first).key?("scope")
  end

  def test_unusable_expires_in_falls_back_to_300s
    ["300", 0, -5, nil, true].each do |expires_in|
      reset_mocks
      @clock.now = 0
      stub_token_endpoint do
        {status: 200, body: JSON.generate(access_token: "access-x", expires_in: expires_in)}
      end
      creds = credentials

      creds.resolve
      @clock.now = 239
      creds.resolve
      assert_equal 1, @token_requests.size, "expires_in #{expires_in.inspect} at t=239"

      @clock.now = 241
      creds.resolve
      assert_equal 2, @token_requests.size, "expires_in #{expires_in.inspect} at t=241"
    end
  end

  def test_unreadable_token_responses_are_invalid_response_and_not_retried
    [
      {status: 200, body: "<html>not json</html>"},
      {status: 200, body: "[]"},
      {status: 200, body: JSON.generate(token_type: "Bearer", expires_in: 300)},
      {status: 200, body: JSON.generate(access_token: "", expires_in: 300)},
      {status: 404, body: "not found"}
    ].each do |response|
      reset_mocks
      stub_token_endpoint { response }

      error = assert_raises(WorkOS::WorkloadIdentityError) { credentials.resolve }

      assert_equal "invalid_response", error.code, response.inspect
      assert_equal 1, @token_requests.size
    end
  end

  def test_exhausted_retries_report_the_oauth_code_when_the_body_has_one
    stub_token_endpoint { {status: 503, body: JSON.generate(error: "temporarily_unavailable", error_description: "try later")} }

    error = assert_raises(WorkOS::WorkloadIdentityError) { credentials.resolve }

    assert_equal "temporarily_unavailable", error.code
    assert_equal "try later", error.description
    assert_equal WorkOS::WorkloadIdentityError::DEFAULT_HINT, error.hint
    assert_equal 1 + WorkOS::BaseClient::DEFAULT_MAX_RETRIES, @token_requests.size
    assert_equal WorkOS::BaseClient::DEFAULT_MAX_RETRIES, @sleeps.size
  end

  def test_exhausted_transport_failures_are_exchange_failed_with_the_cause
    stub_token_endpoint { raise Errno::ECONNREFUSED }

    error = assert_raises(WorkOS::WorkloadIdentityError) { credentials.resolve }

    assert_equal "exchange_failed", error.code
    assert_kind_of Errno::ECONNREFUSED, error.cause
    assert_equal 1 + WorkOS::BaseClient::DEFAULT_MAX_RETRIES, @provider_calls
  end

  def test_description_is_cut_to_500_characters
    stub_token_endpoint { oauth_error("invalid_grant", "x" * 2_000) }

    error = assert_raises(WorkOS::WorkloadIdentityError) { credentials.resolve }

    assert_equal 500, error.description.size
  end

  def test_token_file_and_token_env_fail_as_provider_errors
    missing = File.join(Dir.tmpdir, "workos-wif-missing-#{Process.pid}")
    error = assert_raises(WorkOS::WorkloadIdentityError) { WorkOS::WorkloadIdentity.token_file(missing).call }
    assert_equal "provider_failed", error.code
    assert_includes error.description, missing

    Tempfile.create("workos-wif-empty") do |file|
      file.write(" \n")
      file.flush
      error = assert_raises(WorkOS::WorkloadIdentityError) { WorkOS::WorkloadIdentity.token_file(file.path).call }
      assert_includes error.description, "is empty"
    end

    with_env("MY_JWT" => nil) do
      error = assert_raises(WorkOS::WorkloadIdentityError) { WorkOS::WorkloadIdentity.token_env("MY_JWT").call }
      assert_includes error.description, "MY_JWT"
    end

    stub_token_endpoint
    failed = assert_raises(WorkOS::WorkloadIdentityError) do
      credentials(identity_token_provider: WorkOS::WorkloadIdentity.token_file(missing)).resolve
    end
    assert_equal "provider_failed", failed.code
    assert_includes failed.description, missing
    assert_empty @token_requests
  end

  def test_a_provider_that_returns_nothing_is_a_provider_error
    stub_token_endpoint

    [nil, "", "  \n", 42].each do |value|
      error = assert_raises(WorkOS::WorkloadIdentityError) { credentials(identity_token_provider: -> { value }).resolve }
      assert_equal "provider_failed", error.code
    end
    assert_empty @token_requests
  end

  def test_an_exchange_that_overruns_its_deadline_fails_and_frees_the_slot
    stub_token_endpoint
    hang = Queue.new
    calls = 0
    provider = lambda do
      calls += 1
      hang.pop if calls == 1
      "assertion-1"
    end
    creds = credentials(identity_token_provider: provider)

    with_exchange_deadline(0.1) do
      error = assert_raises(WorkOS::WorkloadIdentityError) { creds.resolve }
      assert_equal "exchange_failed", error.code
      assert_includes error.description, "did not finish"
    end

    assert_equal "Bearer access-1", creds.resolve.headers["Authorization"]
  end

  def test_an_exchange_lost_to_a_fork_is_replaced_in_the_child
    return unless Process.respond_to?(:fork)

    release = Queue.new
    stub_token_endpoint do
      release.pop
      issue_token
    end
    creds = credentials
    parent_caller = Thread.new { creds.resolve.headers["Authorization"] }
    wait_until { @token_requests.size == 1 }

    reader, writer = IO.pipe
    pid = fork do
      reader.close
      # Only the forking thread exists here; the exchange thread is gone.
      release << :respond
      writer.write(creds.resolve(timeout: 5).headers["Authorization"])
      writer.close
      exit!(0)
    end
    writer.close
    child_result = reader.read
    Process.wait(pid)
    release << :respond

    assert_equal "Bearer access-1", child_result
    assert_equal "Bearer access-1", parent_caller.value
  end

  # The provider gems define constants under WorkOS::WorkloadIdentity without
  # depending on this gem. Either load order must leave both usable. Checked
  # in a fresh interpreter, with a stand-in provider and with a real one.
  def test_namespace_survives_a_provider_gem_loaded_first_or_second
    lib = File.expand_path("../../lib", __dir__)
    provider_lib = File.expand_path("../../gems/workos-workload-identity-github-actions/lib", __dir__)
    providers = {
      "stand-in" => [
        "module WorkOS; module WorkloadIdentity; module Fake; def self.provider = -> { 'jwt' }; end; end; end",
        "WorkOS::WorkloadIdentity::Fake.provider"
      ],
      "github-actions gem" => [
        "require 'workos-workload-identity-github-actions'",
        "WorkOS::WorkloadIdentity::GitHubActions.github_actions('https://api.workos.com')"
      ]
    }
    assert File.directory?(provider_lib), "expected the provider gem at #{provider_lib}"

    providers.each do |name, (load_provider, build_provider)|
      check = <<~RUBY
        abort "token_file missing" unless WorkOS::WorkloadIdentity.respond_to?(:token_file)
        abort "constants missing" unless WorkOS::WorkloadIdentity::ENVIRONMENT_HEADER == "x-url-environment-id"
        build = -> { #{build_provider} }
        credentials = WorkOS::WorkloadIdentity::Credentials.new(
          client_id: "c", token_url: "https://t.test/oauth2/token", environment_id: "e",
          identity_token_provider: build.call
        )
        WorkOS::Client.new(credentials: credentials)
        Zeitwerk::Loader.eager_load_all
        abort "provider lost after eager load" unless build.call.respond_to?(:call)
        print "ok"
      RUBY

      {
        "provider first" => "#{load_provider}\nrequire 'workos'\n#{check}",
        "provider second" => "require 'workos'\n#{load_provider}\n#{check}"
      }.each do |order, script|
        output, status = Open3.capture2e(RbConfig.ruby, "-I", lib, "-I", provider_lib, "-e", script)

        assert status.success?, "#{name}, #{order}: #{output}"
        assert_equal "ok", output, "#{name}, #{order}"
      end
    end
  end
end
