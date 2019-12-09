# frozen_string_literal: true

module WorkOS
  # :nodoc:
  class Base
    attr_accessor :key
    class << self
      attr_writer :key
    end

    class << self
      attr_reader :key
    end
  end
end
