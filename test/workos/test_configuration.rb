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

  def test_public_client_accepts_a_proxy
    client = WorkOS::PublicClient.create(client_id: "client_001", proxy: "http://proxy.example.com:8080")

    assert_equal "http://proxy.example.com:8080", client.proxy
  end
end
