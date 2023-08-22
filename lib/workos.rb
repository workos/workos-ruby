# frozen_string_literal: true
# typed: true

require 'workos/version'
require 'sorbet-runtime'
require 'json'
require 'workos/hash_provider'
require 'workos/configuration'

# Use the WorkOS module to authenticate your
# requests to the WorkOS API. The gem will read
# your API key automatically from the ENV var `WORKOS_API_KEY`.
# Alternatively, you can set the key yourself with
# `WorkOS.configure { |config| config.key = [your api key] }` somewhere
# in the load path of your application, such as an initializer.
module WorkOS
  def self.default_config
    Configuration.new.tap do |config|
      config.api_hostname = ENV['WORKOS_API_HOSTNAME'] || 'api.workos.com'
      # Remove WORKOS_KEY at some point in the future. Keeping it here now for
      # backwards compatibility.
      config.key = ENV['WORKOS_API_KEY'] || ENV['WORKOS_KEY']
    end
  end

  def self.config
    @config ||= default_config
  end

  def self.configure
    yield(config)
  end

  def self.key=(value)
    warn '`WorkOS.key=` is deprecated. Use `WorkOS.configure` instead.'

    config.key = value
  end

  def self.key
    warn '`WorkOS.key` is deprecated. Use `WorkOS.configure` instead.'

    config.key
  end

  autoload :Types, 'workos/types'
  autoload :Client, 'workos/client'
  autoload :Configuration, 'workos/configuration'
  autoload :AuditLogExport, 'workos/audit_log_export'
  autoload :AuditLogs, 'workos/audit_logs'
  autoload :AuditTrail, 'workos/audit_trail'
  autoload :Connection, 'workos/connection'
  autoload :DirectorySync, 'workos/directory_sync'
  autoload :Directory, 'workos/directory'
  autoload :DirectoryGroup, 'workos/directory_group'
  autoload :Event, 'workos/event'
  autoload :Events, 'workos/events'
  autoload :Organization, 'workos/organization'
  autoload :Organizations, 'workos/organizations'
  autoload :Passwordless, 'workos/passwordless'
  autoload :Portal, 'workos/portal'
  autoload :Profile, 'workos/profile'
  autoload :ProfileAndToken, 'workos/profile_and_token'
  autoload :SSO, 'workos/sso'
  autoload :DirectoryUser, 'workos/directory_user'
  autoload :Webhook, 'workos/webhook'
  autoload :Webhooks, 'workos/webhooks'
  autoload :MagicAuthChallenge, 'workos/magic_auth_challenge'
  autoload :MFA, 'workos/mfa'
  autoload :Factor, 'workos/factor'
  autoload :Challenge, 'workos/challenge'
  autoload :User, 'workos/user'
  autoload :UserManagement, 'workos/user_management'
  autoload :VerifyChallenge, 'workos/verify_challenge'
  autoload :DeprecatedHashWrapper, 'workos/deprecated_hash_wrapper'


  # Errors
  autoload :APIError, 'workos/errors'
  autoload :AuthenticationError, 'workos/errors'
  autoload :InvalidRequestError, 'workos/errors'
  autoload :SignatureVerificationError, 'workos/errors'
  autoload :TimeoutError, 'workos/errors'
end
