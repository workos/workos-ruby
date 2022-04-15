# frozen_string_literal: true
# typed: true

module WorkOS
  module HashProvider
    # include an explicit method for converting a model into a Hash containing
    # its attributes. Default implementation will simply call to_json.
    def to_h
      to_json
    end
  end
end