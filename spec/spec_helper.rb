# frozen_string_literal: true
# typed: false

require 'simplecov'
SimpleCov.start

if ENV['CI'] == 'true'
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH << File.join(File.dirname(__FILE__))

require 'rubygems'
require 'rspec'
require 'webmock/rspec'
require 'workos'
require 'vcr'

# Support
Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

SPEC_ROOT = File.dirname __FILE__

VCR.configure do |config|
  config.cassette_library_dir = 'spec/support/fixtures/vcr_cassettes'
  config.filter_sensitive_data('<API_KEY>') { WorkOS.config.key }
  config.filter_sensitive_data('<ACCESS_TOKEN>', :token) do |interaction|
    JSON.parse(interaction.response.body)['access_token']
  end
  config.filter_sensitive_data('<REFRESH_TOKEN>', :token) do |interaction|
    JSON.parse(interaction.response.body)['refresh_token']
  end
  config.hook_into :webmock
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  WebMock::API.prepend(Module.new do
    extend self

    # Disable VCR when a WebMock stub is created
    # for clearer spec failure messaging
    def stub_request(*args)
      VCR.turn_off!
      super
    end
  end)

  config.before(:all) { WorkOS.config.key ||= '' }
  config.before(:each) { VCR.turn_on! }
end
