# frozen_string_literal: true

# @oagen-ignore-file
require "net/http"
require "openssl"
require "timeout"
require "uri"
require_relative "gcp/version"

# This gem does not depend on the WorkOS SDK gem. The parent modules are
# opened here so it loads before the SDK, after it, or without it.
module WorkOS
  module WorkloadIdentity
    # Identity token provider for Google Cloud: Compute Engine, GKE, Cloud
    # Run, Cloud Functions and anything else with a metadata server.
    #
    # @example
    #   provider = WorkOS::WorkloadIdentity::GCP.gcp_metadata("https://api.workos.com")
    #   credentials = WorkOS::WorkloadIdentity::Credentials.new(identity_token_provider: provider)
    module GCP
      # Raised when the metadata server cannot supply an identity token.
      class Error < StandardError; end

      # Seconds allowed for the one HTTP request a call makes.
      HTTP_TIMEOUT = 10
      METADATA_BASE_URL = "http://metadata.google.internal"
      IDENTITY_PATH = "/computeMetadata/v1/instance/service-accounts/default/identity"
      USER_AGENT = "workos-workload-identity-gcp/#{VERSION}"

      # @param audience [String] The audience to request the token for. It
      #   must match the audience of the application's trust rule;
      #   conventionally `https://api.workos.com`.
      # @return [#call] A provider: each call makes one HTTP GET to the
      #   metadata server and returns the JWT. It keeps no cache and does not
      #   retry.
      def self.gcp_metadata(audience)
        Provider.new(audience)
      end

      class Provider
        # `base_url` exists for this gem's tests only. It is not an option:
        # the factory does not take it and no environment variable sets it.
        def initialize(audience, base_url: METADATA_BASE_URL)
          raise ArgumentError, "audience is required" unless audience.is_a?(String) && !audience.strip.empty?

          @audience = audience.dup.freeze
          @base_url = base_url
        end

        # @return [String] the service account's identity token
        # @raise [Error]
        def call
          response = get(URI.parse("#{@base_url}#{IDENTITY_PATH}?audience=#{URI.encode_www_form_component(@audience)}&format=full"))
          unless response.code == "200"
            raise Error, "The GCP metadata server answered the identity token request with HTTP #{response.code}."
          end

          token = response.body.to_s.strip
          raise Error, "The GCP metadata server returned an empty identity token." if token.empty?

          token
        end

        private

        # One GET. Net::HTTP does not follow redirects, and its own retry of
        # idempotent requests is turned off: the SDK retries the provider.
        # The metadata server is link-local, so a configured proxy is never used.
        def get(uri)
          request = Net::HTTP::Get.new(uri.request_uri)
          request["Metadata-Flavor"] = "Google"
          request["User-Agent"] = USER_AGENT

          http = Net::HTTP.new(uri.hostname, uri.port, nil)
          http.use_ssl = (uri.scheme == "https")
          http.open_timeout = HTTP_TIMEOUT
          http.read_timeout = HTTP_TIMEOUT
          http.write_timeout = HTTP_TIMEOUT
          http.max_retries = 0
          http.start { |connection| connection.request(request) }
        rescue SystemCallError, SocketError, IOError, Timeout::Error, OpenSSL::SSL::SSLError, Net::ProtocolError => e
          raise Error, "The GCP metadata server could not be reached: #{e.class}"
        end
      end
      private_constant :Provider
    end
  end
end
