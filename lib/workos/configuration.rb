# frozen_string_literal: true
# typed: false

module WorkOS
  # Configuration class sets config initializer
  class Configuration
    attr_accessor :timeout, :key

    def initialize
      @timeout = timeout || 60
      @key = key
    end

    def key!
      key || raise('WorkOS.config.key not set')
    end
  end
end
