# frozen_string_literal: true
# typed: true

require 'workos/version'
require 'sorbet-runtime'

# Use the WorkOS module to authenticate your
# requests to the WorkOS API. The gem will read
# your API key automatically from the ENV var `WORKOS_KEY`.
# Alternatively, you can set the key yourself with
# `WorkOS.key = [your api key]` somewhere in the load path of
# your application, such as an initializer.
module WorkOS
  API_HOSTNAME = 'api.workos.com'

  def self.key=(value)
    Base.key = value
  end

  def self.key
    Base.key
  end

  def self.key!
    key || raise('WorkOS.key not set')
  end

  autoload :Types, 'workos/types'
  autoload :Base, 'workos/base'
  autoload :AuditLog, 'workos/audit_log'
  autoload :Profile, 'workos/profile'
  autoload :SSO, 'workos/sso'

  # Errors
  autoload :APIError, 'workos/errors'
  autoload :AuthenticationError, 'workos/errors'
  autoload :InvalidRequestError, 'workos/errors'

  WorkOS.key = ENV['WORKOS_KEY'] unless ENV['WORKOS_KEY'].nil?
end
