# frozen_string_literal: true

# @oagen-ignore-file
require "test_helper"

class GitHubActionsTest < Minitest::Test
  GitHubActions = WorkOS::WorkloadIdentity::GitHubActions
  AUDIENCE = "https://api.workos.com"
  ENV_NAMES = %w[ACTIONS_ID_TOKEN_REQUEST_URL ACTIONS_ID_TOKEN_REQUEST_TOKEN].freeze

  def setup
    @saved_env = ENV_NAMES.to_h { |name| [name, ENV[name]] }
    @servers = []
  end

  def teardown
    @servers.each(&:close)
    @saved_env.each { |name, value| value.nil? ? ENV.delete(name) : ENV[name] = value }
  end

  def mock(&responder)
    server = MockServer.new(&responder)
    @servers << server
    server
  end

  def point_at(server, token: "gha-request-token")
    ENV["ACTIONS_ID_TOKEN_REQUEST_URL"] = "#{server.url}/token?api-version=2.0"
    ENV["ACTIONS_ID_TOKEN_REQUEST_TOKEN"] = token
  end

  def test_WIF_GHA_01_gets_the_request_url_with_the_audience_appended_and_returns_value
    server = mock { [200, {"Content-Type" => "application/json"}, '{"value": "gha-jwt"}'] }
    point_at(server)

    token = GitHubActions.github_actions(AUDIENCE).call

    assert_equal "gha-jwt", token
    assert_equal 1, server.requests.size
    request = server.requests.first
    assert_equal "GET", request.method
    assert_equal "/token?api-version=2.0&audience=https%3A%2F%2Fapi.workos.com", request.target
    assert_equal "Bearer gha-request-token", request.headers["authorization"]
    assert_equal "application/json", request.headers["accept"]
  end

  def test_WIF_GHA_02_missing_env_vars_fail_with_the_permission_hint_and_no_request
    server = mock { [200, {}, '{"value": "gha-jwt"}'] }

    ENV_NAMES.each do |missing|
      ["", nil].each do |value|
        point_at(server)
        value.nil? ? ENV.delete(missing) : ENV[missing] = value

        error = assert_raises(GitHubActions::Error) { GitHubActions.github_actions(AUDIENCE).call }

        assert_includes error.message, "permissions: id-token: write", "#{missing}=#{value.inspect}"
      end
    end
    assert_empty server.requests
  end

  def test_the_environment_is_read_on_every_call
    first = mock { [200, {}, '{"value": "jwt-1"}'] }
    second = mock { [200, {}, '{"value": "jwt-2"}'] }
    provider = GitHubActions.github_actions(AUDIENCE)

    point_at(first, token: "request-token-1")
    assert_equal "jwt-1", provider.call
    point_at(second, token: "request-token-2")
    assert_equal "jwt-2", provider.call

    assert_equal "Bearer request-token-2", second.requests.first.headers["authorization"]
  end

  def test_the_audience_is_percent_encoded
    server = mock { [200, {}, '{"value": "gha-jwt"}'] }
    point_at(server)

    GitHubActions.github_actions("api://workos/a b&c=d").call

    assert_equal "/token?api-version=2.0&audience=api%3A%2F%2Fworkos%2Fa+b%26c%3Dd", server.requests.first.target
  end

  def test_a_request_url_without_a_query_gets_one
    server = mock { [200, {}, '{"value": "gha-jwt"}'] }
    ENV["ACTIONS_ID_TOKEN_REQUEST_URL"] = "#{server.url}/token"
    ENV["ACTIONS_ID_TOKEN_REQUEST_TOKEN"] = "gha-request-token"

    GitHubActions.github_actions(AUDIENCE).call

    assert_equal "/token?audience=https%3A%2F%2Fapi.workos.com", server.requests.first.target
  end

  def test_a_non_200_names_the_status
    server = mock { [404, {}, "not found"] }
    point_at(server)

    error = assert_raises(GitHubActions::Error) { GitHubActions.github_actions(AUDIENCE).call }

    assert_includes error.message, "404"
  end

  def test_a_redirect_is_an_error_and_is_not_followed
    elsewhere = mock { [200, {}, '{"value": "stolen-jwt"}'] }
    server = mock { [302, {"Location" => "#{elsewhere.url}/token"}, ""] }
    point_at(server)

    error = assert_raises(GitHubActions::Error) { GitHubActions.github_actions(AUDIENCE).call }

    assert_includes error.message, "302"
    assert_equal 1, server.requests.size
    assert_empty elsewhere.requests
  end

  def test_a_missing_or_empty_value_is_an_error
    ['{"value": ""}', "{}", "[]", "not json", ""].each do |body|
      server = mock { [200, {}, body] }
      point_at(server)

      assert_raises(GitHubActions::Error, body) { GitHubActions.github_actions(AUDIENCE).call }
    end
  end

  def test_errors_never_contain_the_request_token_or_the_jwt
    server = mock { [500, {}, '{"value": "SECRET-JWT"}'] }
    point_at(server, token: "SECRET-REQUEST-TOKEN")
    errors = [assert_raises(GitHubActions::Error) { GitHubActions.github_actions(AUDIENCE).call }]

    ENV["ACTIONS_ID_TOKEN_REQUEST_URL"] = "http://127.0.0.1:1/token?api-version=2.0"
    errors << assert_raises(GitHubActions::Error) { GitHubActions.github_actions(AUDIENCE).call }

    errors.each do |error|
      [error.message, error.inspect, error.full_message(highlight: false)].each do |text|
        refute_includes text, "SECRET-REQUEST-TOKEN"
        refute_includes text, "SECRET-JWT"
      end
    end
  end

  def test_an_audience_is_required
    assert_raises(ArgumentError) { GitHubActions.github_actions(nil) }
    assert_raises(ArgumentError) { GitHubActions.github_actions(" ") }
  end

  # A provider is anything that responds to `call`; nothing here needs the
  # WorkOS SDK gem, and the SDK is not installed for these tests.
  def test_loads_and_works_without_the_workos_sdk
    refute defined?(WorkOS::BaseClient)
    refute defined?(WorkOS::Client)
    assert_respond_to GitHubActions.github_actions(AUDIENCE), :call
    assert_match(/\A\d+\.\d+\.\d+\z/, GitHubActions::VERSION)
  end
end
