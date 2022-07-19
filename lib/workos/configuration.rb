# frozen_string_literal: true
# typed: true

module WorkOS
  # Configuration class sets config initializer
  class Configuration
    attr_accessor :timeout, :key

    def initialize
      @timeout = 60
    end

    def key!
      key or raise '`WorkOS.config.key` not set'
    end
  end
end
