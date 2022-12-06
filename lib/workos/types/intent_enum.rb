# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # The IntentEnum is type-safe declarations of a fixed set of values for
    # intents while generating an Admin Portal link.
    class Intent < T::Enum
      enums do
        AUDIT_LOGS = new('audit_logs')
        DSYNC = new('dsync')
        LOG_STREAMS = new('log_streams')
        SSO = new('sso')
      end
    end
  end
end
