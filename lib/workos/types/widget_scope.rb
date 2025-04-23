# frozen_string_literal: true

module WorkOS
  module Types
    # The WidgetScope constants are declarations of a fixed set of values for
    # scopes while generating a widget token.
    module WidgetScope
      USERS_TABLE_MANAGE = 'widgets:users-table:manage'

      ALL = [USERS_TABLE_MANAGE].freeze
    end
  end
end
