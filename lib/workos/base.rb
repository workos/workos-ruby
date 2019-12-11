# frozen_string_literal: true
# typed: true
# rubocop:disable Style/Documentation


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
# rubocop:enable Style/Documentation
