# frozen_string_literal: true

module WorkOS
  module Deprecation
    def warn_deprecation(message)
      full_message = "[DEPRECATION] #{message}"

      if RUBY_VERSION > '3'
        warn full_message, category: :deprecated
      else
        warn full_message
      end
    end
  end
end
