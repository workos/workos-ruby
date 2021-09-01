# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # This WebhookStruct acts as a typed interface
    # for the Webhook class
    class WebhookStruct < T::Struct
      const :event, String
      const :data, T::Hash[Symbol, Object]
    end
  end
end
