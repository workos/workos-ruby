# frozen_string_literal: true
# typed: true


module WorkOS
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
