# frozen_string_literal: true

# @oagen-ignore-file
require "test_helper"

class AWSTest < Minitest::Test
  AWS = WorkOS::WorkloadIdentity::AWS
  AUDIENCE = "https://api.workos.com"

  # The one-method seam: everything the provider asks of an STS client.
  class StubSTS
    Response = Struct.new(:web_identity_token)

    attr_reader :calls

    def initialize(token: "aws-jwt", error: nil)
      @token = token
      @error = error
      @calls = []
    end

    def get_web_identity_token(**params)
      @calls << params
      raise @error if @error

      Response.new(@token)
    end
  end

  def provider_with(sts, region = "us-east-1")
    AWS.const_get(:Provider).new(AUDIENCE, region, sts_client: sts)
  end

  def sts_client_of(provider)
    provider.instance_variable_get(:@sts_client)
  end

  # Where a request from this client would go, resolved by the AWS SDK's own
  # endpoint rules without sending anything.
  def endpoint_of(client)
    client.config.endpoint_provider.resolve_endpoint(Aws::STS::EndpointParameters.create(client.config)).url
  end

  def with_env(values)
    saved = values.to_h { |name, _value| [name, ENV[name]] }
    values.each { |name, value| value.nil? ? ENV.delete(name) : ENV[name] = value }
    yield
  ensure
    saved.each { |name, value| value.nil? ? ENV.delete(name) : ENV[name] = value }
  end

  def test_WIF_AWS_01_calls_get_web_identity_token_with_the_audience_and_rs256_on_a_regional_endpoint
    sts = StubSTS.new

    token = provider_with(sts).call

    assert_equal "aws-jwt", token
    assert_equal [{audience: ["https://api.workos.com"], signing_algorithm: "RS256"}], sts.calls

    # The client the factory builds for us-east-1.
    client = sts_client_of(AWS.aws_sts(AUDIENCE, "us-east-1"))
    assert_kind_of Aws::STS::Client, client
    assert_respond_to client, :get_web_identity_token
    assert_equal "us-east-1", client.config.region
    assert_equal "https://sts.us-east-1.amazonaws.com", endpoint_of(client)
    refute_equal "https://sts.amazonaws.com", endpoint_of(client)

    # With no region available, building the provider is an error.
    error = assert_raises(AWS::Error) { AWS.aws_sts(AUDIENCE) }
    assert_includes error.message, "region"
  end

  def test_WIF_AWS_02_an_sts_error_surfaces_as_a_provider_error_naming_the_call
    denied = Aws::STS::Errors::AccessDenied.new(
      nil,
      "User: arn:aws:sts::123456789012:assumed-role/app/i-0abc is not authorized to perform: sts:GetWebIdentityToken"
    )
    sts = StubSTS.new(token: "SECRET-AWS-JWT", error: denied)

    error = assert_raises(AWS::Error) { provider_with(sts).call }

    assert_includes error.message, "sts:GetWebIdentityToken"
    assert_includes error.message, "AccessDenied"
    [error.message, error.inspect, error.full_message(highlight: false)].each do |text|
      refute_includes text, "SECRET-AWS-JWT"
    end
    assert_equal 1, sts.calls.size
  end

  def test_the_region_falls_back_to_what_the_aws_sdk_resolves
    with_env("AWS_REGION" => "eu-west-1") do
      client = sts_client_of(AWS.aws_sts(AUDIENCE))

      assert_equal "eu-west-1", client.config.region
      assert_equal "https://sts.eu-west-1.amazonaws.com", endpoint_of(client)
    end
  end

  def test_the_regional_endpoint_is_kept_when_the_environment_asks_for_the_legacy_global_one
    with_env("AWS_STS_REGIONAL_ENDPOINTS" => "legacy") do
      assert_equal "https://sts.amazonaws.com", endpoint_of(Aws::STS::Client.new(region: "us-east-1"))

      assert_equal "https://sts.us-east-1.amazonaws.com", endpoint_of(sts_client_of(AWS.aws_sts(AUDIENCE, "us-east-1")))
    end
  end

  def test_a_global_pseudo_region_is_rejected
    error = assert_raises(AWS::Error) { AWS.aws_sts(AUDIENCE, "aws-global") }

    assert_includes error.message, "aws-global"
  end

  def test_an_invalid_region_is_a_one_line_error
    error = assert_raises(AWS::Error) { AWS.aws_sts(AUDIENCE, "not a region") }

    assert_equal 1, error.message.lines.size
  end

  def test_the_sts_client_is_built_once_and_reused
    sts = StubSTS.new
    provider = provider_with(sts)

    3.times { provider.call }

    assert_equal 3, sts.calls.size
    assert_same sts, sts_client_of(provider)
  end

  def test_the_aws_sdk_does_not_retry_because_the_workos_sdk_retries_the_provider
    assert_operator Aws::STS::Client.new(region: "us-east-1").config.max_attempts, :>, 1

    config = sts_client_of(AWS.aws_sts(AUDIENCE, "us-east-1")).config

    assert_equal 1, config.max_attempts
    assert_equal 0, config.retry_limit
  end

  def test_no_duration_is_sent_so_sts_applies_its_default
    sts = StubSTS.new

    provider_with(sts).call

    refute sts.calls.first.key?(:duration_seconds)
  end

  def test_a_response_without_a_token_and_a_non_service_failure_name_the_call
    empty = assert_raises(AWS::Error) { provider_with(StubSTS.new(token: "")).call }
    assert_includes empty.message, "sts:GetWebIdentityToken"

    network = assert_raises(AWS::Error) do
      provider_with(StubSTS.new(error: Seahorse::Client::NetworkingError.new(SocketError.new("no route")))).call
    end
    assert_includes network.message, "sts:GetWebIdentityToken"
  end

  def test_an_audience_is_required
    assert_raises(ArgumentError) { AWS.aws_sts(nil, "us-east-1") }
    assert_raises(ArgumentError) { AWS.aws_sts("", "us-east-1") }
  end

  def test_inspect_does_not_dump_the_sts_client
    assert_equal '#<WorkOS::WorkloadIdentity::AWS::Provider audience="https://api.workos.com">', AWS.aws_sts(AUDIENCE, "us-east-1").inspect
  end

  # A provider is anything that responds to `call`; nothing here needs the
  # WorkOS SDK gem, and the SDK is not installed for these tests.
  def test_loads_and_works_without_the_workos_sdk
    refute defined?(WorkOS::BaseClient)
    refute defined?(WorkOS::Client)
    assert_respond_to AWS.aws_sts(AUDIENCE, "us-east-1"), :call
    assert_match(/\A\d+\.\d+\.\d+\z/, AWS::VERSION)
  end
end
