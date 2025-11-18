# frozen_string_literal: true

module WorkOS
  # Configuration class sets config initializer
  class Configuration
    attr_accessor :api_hostname, :timeout, :key, :max_retries, :auto_idempotency_keys

    def initialize
      @timeout = 60
      @max_retries = 3
      @auto_idempotency_keys = true
    end

    def key!
      key or raise '`WorkOS.config.key` not set'
    end
  end
end
