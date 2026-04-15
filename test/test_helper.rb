# frozen_string_literal: true

$LOAD_PATH << File.join(File.dirname(__FILE__), "..", "lib")
$LOAD_PATH << File.join(File.dirname(__FILE__))

require "minitest/autorun"
require "webmock/minitest"
require "workos"
require "vcr"

TEST_ROOT = File.dirname(__FILE__)

VCR.configure do |config|
  config.cassette_library_dir = "test/fixtures/vcr_cassettes"
  config.filter_sensitive_data("<API_KEY>") { WorkOS.config.key }
  config.filter_sensitive_data("<ACCESS_TOKEN>", :token) do |interaction|
    JSON.parse(interaction.response.body)["access_token"]
  end
  config.filter_sensitive_data("<REFRESH_TOKEN>", :token) do |interaction|
    JSON.parse(interaction.response.body)["refresh_token"]
  end
  config.hook_into :webmock
end

class WorkOS::TestCase < Minitest::Test
  def setup
    WorkOS.instance_variable_set(:@config, WorkOS.default_config)
    WorkOS.config.key ||= ""
    VCR.turn_on!
  end

  # Helper to temporarily disable VCR when using WebMock stubs directly
  def with_vcr_off
    VCR.turn_off!
    yield
  ensure
    VCR.turn_on!
  end
end
