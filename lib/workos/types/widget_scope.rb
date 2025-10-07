# frozen_string_literal: true

module WorkOS
  module Types
    # The WidgetScope constants are declarations of a fixed set of values for
    # scopes while generating a widget token.
    module WidgetScope
      USERS_TABLE_MANAGE = 'widgets:users-table:manage'
      SSO_MANAGE = 'widgets:sso:manage'
      DOMAIN_VERIFICATION_MANAGE = 'widgets:domain-verification:manage'

      ALL = [USERS_TABLE_MANAGE, SSO_MANAGE, DOMAIN_VERIFICATION_MANAGE].freeze
    end
  end
end
