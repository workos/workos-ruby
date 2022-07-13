# frozen_string_literal: true
# typed: false

module WorkOS
  # Configuration class sets config initializer
  class Configuration
    attr_accessor :timeout

    def initialize
      @timeout = timeout || 60
    end
  end
end
