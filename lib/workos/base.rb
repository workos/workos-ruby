# frozen_string_literal: true
# typed: true


module WorkOS
  ## The Base class handles setting and reading the WorkOS
  ## API Key for authentication
  module Base
    attr_accessor :key

    class << self
      extend T::Sig

      attr_writer :key
      attr_reader :key
    end
  end
end
