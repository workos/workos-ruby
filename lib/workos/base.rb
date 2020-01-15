# frozen_string_literal: true
# typed: true

# rubocop:disable Style/Documentation
module WorkOS
  module Base
    attr_accessor :key

    class << self
      extend T::Sig

      attr_writer :key
      attr_reader :key
    end
  end
end
# rubocop:enable Style/Documentation
