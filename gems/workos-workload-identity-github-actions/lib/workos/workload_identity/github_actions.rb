# frozen_string_literal: true

# @oagen-ignore-file
require "json"
require "net/http"
require "openssl"
require "timeout"
require "uri"
require_relative "github_actions/version"

# This gem does not depend on the WorkOS SDK gem. The parent modules are
# opened here so it loads before the SDK, after it, or without it.
module WorkOS
  module WorkloadIdentity
    # Identity token provider for GitHub Actions.
    #
    # The workflow or job must grant `permissions: id-token: write`.
    #
    # @example
    #   provider = WorkOS::WorkloadIdentity::GitHubActions.github_actions("https://api.workos.com")
    #   credentials = WorkOS::WorkloadIdentity::Credentials.new(identity_token_provider: provider)
    module GitHubActions
      # Raised when GitHub Actions cannot supply an identity token.
      class Error < StandardError; end

      # Seconds allowed for the one HTTP request a call makes.
      HTTP_TIMEOUT = 10
      REQUEST_URL_ENV = "ACTIONS_ID_TOKEN_REQUEST_URL"
      REQUEST_TOKEN_ENV = "ACTIONS_ID_TOKEN_REQUEST_TOKEN"
      MISSING_ENDPOINT = "GitHub Actions did not provide an OIDC token endpoint. " \
        "Add `permissions: id-token: write` to the workflow or job."
      USER_AGENT = "workos-workload-identity-github-actions/#{VERSION}"

      # @param audience [String] The audience to request the token for. It
      #   must match the audience of the application's trust rule;
      #   conventionally `https://api.workos.com`.
      # @return [#call] A provider: each call makes one HTTP GET and returns
      #   the JWT. It keeps no cache and does not retry.
      def self.github_actions(audience)
        Provider.new(audience)
      end

      class Provider
        def initialize(audience)
          raise ArgumentError, "audience is required" unless audience.is_a?(String) && !audience.strip.empty?

          @audience = audience.dup.freeze
        end

        # @return [String] the GitHub Actions OIDC token
        # @raise [Error]
        def call
          # Both are read on every call.
          url = ENV[REQUEST_URL_ENV].to_s
          request_token = ENV[REQUEST_TOKEN_ENV].to_s
          raise Error, MISSING_ENDPOINT if url.empty? || request_token.empty?

          response = get(endpoint(url), request_token)
          unless response.code == "200"
            raise Error, "The GitHub Actions OIDC token request failed with HTTP #{response.code}."
          end

          token = parse(response.body)["value"]
          unless token.is_a?(String) && !token.empty?
            raise Error, "The GitHub Actions OIDC token response had no token."
          end

          token
        end

        private

        # The request URL already has a query string; the audience is added
        # to it, never put in its place.
        def endpoint(url)
          uri = begin
            URI.parse(url)
          rescue URI::InvalidURIError
            nil
          end
          unless uri.is_a?(URI::HTTP) && uri.hostname
            raise Error, "#{REQUEST_URL_ENV} is not an http or https URL."
          end

          audience = "audience=#{URI.encode_www_form_component(@audience)}"
          uri.query = [uri.query, audience].compact.reject(&:empty?).join("&")
          uri
        end

        # One GET. Net::HTTP does not follow redirects, and its own retry of
        # idempotent requests is turned off: the SDK retries the provider.
        def get(uri, request_token)
          request = Net::HTTP::Get.new(uri.request_uri)
          request["Authorization"] = "Bearer #{request_token}"
          request["Accept"] = "application/json"
          request["User-Agent"] = USER_AGENT

          http = Net::HTTP.new(uri.hostname, uri.port)
          http.use_ssl = (uri.scheme == "https")
          http.open_timeout = HTTP_TIMEOUT
          http.read_timeout = HTTP_TIMEOUT
          http.write_timeout = HTTP_TIMEOUT
          http.max_retries = 0
          http.start { |connection| connection.request(request) }
        rescue SystemCallError, SocketError, IOError, Timeout::Error, OpenSSL::SSL::SSLError, Net::ProtocolError => e
          raise Error, "The GitHub Actions OIDC token request failed: #{e.class}"
        end

        def parse(body)
          parsed = JSON.parse(body.to_s)
          parsed.is_a?(Hash) ? parsed : {}
        rescue JSON::ParserError
          {}
        end
      end
      private_constant :Provider
    end
  end
end
