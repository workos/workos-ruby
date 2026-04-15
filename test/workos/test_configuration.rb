# frozen_string_literal: true

require "test_helper"

class TestConfiguration < WorkOS::TestCase
  def setup
    super
    WorkOS.instance_variable_set(:@config, WorkOS::Configuration.new)
  end

  def test_configure_with_key_and_no_timeout
    WorkOS.configure do |config|
      config.key = "example_api_key"
    end

    assert_equal "example_api_key", WorkOS.config.key
    assert_equal 60, WorkOS.config.timeout
  end

  def test_configure_with_key_and_timeout
    WorkOS.configure do |config|
      config.key = "example_api_key"
      config.timeout = 120
    end

    assert_equal "example_api_key", WorkOS.config.key
    assert_equal 120, WorkOS.config.timeout
  end

  def test_key_bang_returns_the_key_when_set
    WorkOS.config.key = "example_api_key"

    assert_equal "example_api_key", WorkOS.config.key!
  end

  def test_key_bang_raises_error_when_key_not_set
    WorkOS.config.key = nil

    err = assert_raises(RuntimeError) do
      WorkOS.config.key!
    end
    assert_equal "`WorkOS.config.key` not set", err.message
  end
end
