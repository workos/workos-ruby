# frozen_string_literal: true
# typed: true

module WorkOS
  # Module to include an explicit method for converting a model into a Hash containing
  # its attributes. Default implementation will simply call to_json. Individual classes
  # may override.
  module HashProvider
    def to_h
      to_json
    end
  end
end
