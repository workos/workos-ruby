# frozen_string_literal: true

module WorkOS
  # Configuration class sets config initializer
  class Configuration
    attr_accessor :api_hostname, :timeout, :key, :max_retries

    def initialize
      @timeout = 60
      @max_retries = 0
    end

    def key!
      key or raise '`WorkOS.config.key` not set'
    end
  end
end
