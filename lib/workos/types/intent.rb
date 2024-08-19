# frozen_string_literal: true

module WorkOS
  module Types
    # The Intent constants are declarations of a fixed set of values for
    # intents while generating an Admin Portal link.
    module Intent
      AUDIT_LOGS = 'audit_logs'
      CERTIFICATE_RENEWAL = 'certificate_renewal'
      DSYNC = 'dsync'
      LOG_STREAMS = 'log_streams'
      SSO = 'sso'

      ALL = [AUDIT_LOGS, CERTIFICATE_RENEWAL, DSYNC, LOG_STREAMS, SSO].freeze
    end
  end
end
