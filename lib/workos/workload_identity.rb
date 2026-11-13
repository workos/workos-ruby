# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained runtime
require "workos/errors"

module WorkOS
  # Workload identity federation: authenticate to the WorkOS API with a
  # short-lived token issued by the platform the code runs on, in place of an
  # API key.
  #
  # @example
  #   credentials = WorkOS::WorkloadIdentity::Credentials.new(
  #     client_id: "client_...",
  #     token_url: "https://.../oauth2/token",
  #     environment_id: "environment_...",
  #     identity_token_provider: WorkOS::WorkloadIdentity.token_file("/var/run/secrets/workos/token")
  #   )
  #   client = WorkOS::Client.new(credentials: credentials)
  #
  # The platform providers (GitHub Actions, GCP, AWS) ship as separate gems.
  # They define their own constants under this module and do not depend on
  # this gem, so this module may already exist when this file loads.
  # `workos/configuration` requires this file explicitly for that reason:
  # Zeitwerk skips a file whose constant is already defined.
  module WorkloadIdentity
    # Sent on every API request made with workload identity credentials that
    # have an environment ID. Left out when they have none.
    ENVIRONMENT_HEADER = "x-url-environment-id"
    GRANT_TYPE = "urn:ietf:params:oauth:grant-type:jwt-bearer"
    DEFAULT_RESOURCE = "https://api.workos.com"
    # A token is refreshed once less than min(REFRESH_THRESHOLD seconds,
    # REFRESH_FRACTION of its lifetime) remains.
    REFRESH_THRESHOLD = 60
    REFRESH_FRACTION = 0.2
    # Lifetime, in seconds, of a token whose response has no usable `expires_in`.
    DEFAULT_LIFETIME = 300
    # Seconds allowed for one whole exchange, including retries and backoff.
    EXCHANGE_DEADLINE = 30

    # An identity token provider that reads the token from a file. The file is
    # read again on every exchange, so a rotated token is picked up.
    #
    # @param path [String, Pathname]
    # @return [#call]
    def self.token_file(path)
      path = path.to_s
      raise ArgumentError, "path is required" if path.empty?

      lambda do
        token = begin
          File.read(path).strip
        rescue SystemCallError, IOError => e
          raise WorkloadIdentityError.new(code: "provider_failed", description: "could not read the token file #{path} (#{e.class})")
        end
        raise WorkloadIdentityError.new(code: "provider_failed", description: "the token file #{path} is empty") if token.empty?

        token
      end
    end

    # An identity token provider that reads the token from an environment
    # variable. The variable is read again on every exchange.
    #
    # @param name [String]
    # @return [#call]
    def self.token_env(name)
      name = name.to_s
      raise ArgumentError, "name is required" if name.empty?

      lambda do
        token = ENV[name].to_s.strip
        raise WorkloadIdentityError.new(code: "provider_failed", description: "the environment variable #{name} is unset or empty") if token.empty?

        token
      end
    end
  end
end
