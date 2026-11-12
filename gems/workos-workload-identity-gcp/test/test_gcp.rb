# frozen_string_literal: true

# @oagen-ignore-file
require "test_helper"

class GCPTest < Minitest::Test
  GCP = WorkOS::WorkloadIdentity::GCP
  AUDIENCE = "https://api.workos.com"
  IDENTITY_PATH = "/computeMetadata/v1/instance/service-accounts/default/identity"

  def setup
    @servers = []
  end

  def teardown
    @servers.each(&:close)
  end

  def mock(&responder)
    server = MockServer.new(&responder)
    @servers << server
    server
  end

  # The factory takes an audience and nothing else. The metadata base URL is
  # pointed at the mock through the provider's internal setting.
  def provider_for(server, audience = AUDIENCE)
    GCP.const_get(:Provider).new(audience, base_url: server.url)
  end

  def test_WIF_GCP_01_gets_the_metadata_identity_url_and_returns_the_body
    server = mock { [200, {"Content-Type" => "application/text"}, "gcp-jwt\n"] }

    token = provider_for(server).call

    assert_equal "gcp-jwt", token
    assert_equal 1, server.requests.size
    request = server.requests.first
    assert_equal "GET", request.method
    assert_equal "#{IDENTITY_PATH}?audience=https%3A%2F%2Fapi.workos.com&format=full", request.target
    assert_equal "Google", request.headers["metadata-flavor"]
  end

  def test_WIF_GCP_02_a_non_200_or_an_empty_body_is_an_error_and_no_redirect_is_followed
    not_found = mock { [404, {}, "not found"] }
    error = assert_raises(GCP::Error) { provider_for(not_found).call }
    assert_includes error.message, "404"

    empty = mock { [200, {}, " \n"] }
    assert_raises(GCP::Error) { provider_for(empty).call }

    elsewhere = mock { [200, {}, "stolen-jwt"] }
    redirect = mock { [302, {"Location" => "#{elsewhere.url}#{IDENTITY_PATH}"}, ""] }
    error = assert_raises(GCP::Error) { provider_for(redirect).call }
    assert_includes error.message, "302"
    assert_equal 1, redirect.requests.size
    assert_empty elsewhere.requests
  end

  def test_the_factory_targets_the_metadata_server_and_takes_only_an_audience
    provider = GCP.gcp_metadata(AUDIENCE)

    assert_respond_to provider, :call
    assert_equal "http://metadata.google.internal", provider.instance_variable_get(:@base_url)
    assert_equal 1, GCP.method(:gcp_metadata).arity
  end

  def test_the_audience_is_percent_encoded
    server = mock { [200, {}, "gcp-jwt"] }

    provider_for(server, "api://workos/a b&c=d").call

    assert_equal "#{IDENTITY_PATH}?audience=api%3A%2F%2Fworkos%2Fa+b%26c%3Dd&format=full", server.requests.first.target
  end

  def test_an_unreachable_metadata_server_is_an_error_without_the_token
    closed = mock { [200, {}, "gcp-jwt"] }
    url = closed.url
    closed.close
    @servers.delete(closed)

    error = assert_raises(GCP::Error) { GCP.const_get(:Provider).new(AUDIENCE, base_url: url).call }

    assert_includes error.message, "could not be reached"
  end

  def test_WIF_GCP_03_a_configured_proxy_is_never_used
    server = mock { [200, {}, "gcp-jwt"] }
    ENV["http_proxy"] = "http://127.0.0.1:1"

    assert_equal "gcp-jwt", provider_for(server).call
  ensure
    ENV.delete("http_proxy")
  end

  def test_an_audience_is_required
    assert_raises(ArgumentError) { GCP.gcp_metadata(nil) }
    assert_raises(ArgumentError) { GCP.gcp_metadata("") }
  end

  # A provider is anything that responds to `call`; nothing here needs the
  # WorkOS SDK gem, and the SDK is not installed for these tests.
  def test_loads_and_works_without_the_workos_sdk
    refute defined?(WorkOS::BaseClient)
    refute defined?(WorkOS::Client)
    assert_match(/\A\d+\.\d+\.\d+\z/, GCP::VERSION)
  end
end
