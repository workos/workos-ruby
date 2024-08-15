# frozen_string_literal: true

module WorkOS
  module Types
    # The Intent constants are declarations of a fixed set of values for
    # intents while generating an Admin Portal link.
    module Intent
      AUDIT_LOGS = 'audit_logs'
      DSYNC = 'dsync'
      LOG_STREAMS = 'log_streams'
      SSO = 'sso'
      CERTIFICATE_RENEWAL = 'certificate_renewal'

      ALL = [AUDIT_LOGS, DSYNC, LOG_STREAMS, SSO, CERTIFICATE_RENEWAL].freeze
    end
  end
end
