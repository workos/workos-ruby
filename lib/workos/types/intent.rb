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
      DOMAIN_VERIFICATION = 'domain_verification'

      ALL = [AUDIT_LOGS, CERTIFICATE_RENEWAL, DSYNC, LOG_STREAMS, SSO, DOMAIN_VERIFICATION].freeze
    end
  end
end
