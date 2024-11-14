# frozen_string_literal: true

module WorkOS
  # Types contains a few structs wrapping up common data structures.
  module Types
    autoload :Provider, 'workos/types/provider'
    autoload :Intent, 'workos/types/intent'
    autoload :ListStruct, 'workos/types/list_struct'
    autoload :PasswordlessSessionStruct, 'workos/types/passwordless_session_struct'
    autoload :WidgetScope, 'workos/types/widget_scope'
  end
end
