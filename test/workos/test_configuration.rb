# frozen_string_literal: true

# @oagen-ignore-file
require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @original_proxy = WorkOS.configuration.proxy
    WorkOS.reset_client
  end

  def teardown
    WorkOS.configuration.proxy = @original_proxy
    WorkOS.reset_client
  end

  def test_proxy_defaults_to_nil
    assert_nil WorkOS::Configuration.new.proxy
    assert_nil WorkOS.client.proxy
  end

  def test_configured_proxy_is_passed_to_the_singleton_client
    WorkOS.configure { |config| config.proxy = "http://proxy.example.com:8080" }

    assert_equal "http://proxy.example.com:8080", WorkOS.client.proxy
  end

  # A mistake in an initializer should fail at boot, not on the first request.
  def test_invalid_proxy_is_rejected_when_it_is_assigned
    config = WorkOS::Configuration.new

    ["proxy.example.com:8080", "https://proxy.example.com", ""].each do |value|
      assert_raises(ArgumentError, "expected #{value.inspect} to be rejected") { config.proxy = value }
    end
    assert_nil config.proxy
  end

  def test_configure_reports_an_invalid_proxy_without_leaking_credentials
    error = assert_raises(ArgumentError) do
      WorkOS.configure { |config| config.proxy = "https://user:s3cret@proxy.example.com" }
    end

    refute_includes error.message, "s3cret"
  end

  def test_proxy_can_be_cleared
    config = WorkOS::Configuration.new
    config.proxy = "http://proxy.example.com:8080"
    config.proxy = nil

    assert_nil config.proxy
  end

  def test_public_client_accepts_a_proxy
    client = WorkOS::PublicClient.create(client_id: "client_001", proxy: "http://proxy.example.com:8080")

    assert_equal "http://proxy.example.com:8080", client.proxy
  end
end
