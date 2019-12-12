# frozen_string_literal: true
# typed: true


require 'net/http'
require 'rack/utils'
require 'uri'

module WorkOS
  # The SSO module provides convenience methods for working with the WorkOS
  # SSO service. You'll need a valid API key, a project ID, and to have
  # created an SSO connection on your WorkOS dashboard.
  #
  # @see https://dashboard.workos.com/docs/sso/what-is-sso
  module SSO
    class << self
      extend T::Sig

      sig do
        params(
          domain: String,
          project_id: String,
          redirect_uri: String,
          state: Hash,
        ).returns(String)
      end

      # Generate an Oauth2 authorization URL where your users will
      # authenticate using the configured SSO Identity Provider.
      #
      # @param [String] domain The domain for the relevant SSO Connection
      #  configured on your WorkOS dashboard
      # @param [String] project_id The WorkOS project ID for the project
      #  where you've  configured your SSO connection
      # @param [String] redirect_uri The URI where users are directed
      #  after completing the authentication step. Must match a
      #  configured redirect URI on your WorkOS dashboard
      # @param [Hash] state An aribtrary state object
      #  that is preserved and available to the client in the response.
      # @example
      #   WorkOS::SSO.authorization_url(
      #     domain: 'acme.com',
      #     project_id: 'project_01DG5TGK363GRVXP3ZS40WNGEZ',
      #     redirect_uri: 'https://workos.com/callback',
      #     state: {
      #       next_page: '/docs'
      #     }
      #   )
      #
      #   => "https://api.workos.com/sso/authorize?domain=acme.com" \
      #      "&client_id=project_01DG5TGK363GRVXP3ZS40WNGEZ" \
      #      "&redirect_uri=https%3A%2F%2Fworkos.com%2Fcallback&" \
      #      "response_type=code&state=%7B%3Anext_page%3D%3E%22%2Fdocs%22%7D"
      #
      # @return [String]
      def authorization_url(domain:, project_id:, redirect_uri:, state: {})
        query = Rack::Utils.build_query(
          domain: domain,
          client_id: project_id,
          redirect_uri: redirect_uri,
          response_type: 'code',
          state: state,
        )

        "https://#{WorkOS::API_HOSTNAME}/sso/authorize?#{query}"
      end

      sig do
        params(
          code: String,
          project_id: String,
          redirect_uri: String,
        ).returns(WorkOS::Profile)
      end

      # Fetch the profile details for the authenticated SSO user.
      #
      # @param [String] code The authorization code provided in the callback URL
      # @param [String] project_id The WorkOS project ID for the project
      #  where you've  configured your SSO connection
      # @param [String] redirect_uri The URI where the user was directed
      #  after completing the authentication step.
      #
      # @example
      #   WorkOS::SSO.profile(
      #     code: 'acme.com',
      #     project_id: 'project_01DG5TGK363GRVXP3ZS40WNGEZ',
      #     redirect_uri: 'https://workos.com/callback',
      #   )
      #   => #<WorkOS::Profile:0x00007fb6e4193d20
      #         @id="prof_01DRA1XNSJDZ19A31F183ECQW5",
      #         @email="demo@workos-okta.com",
      #         @first_name="WorkOS",
      #         @connection_type="OktaSAML",
      #         @last_name="Demo",
      #         @idp_id="00u1klkowm8EGah2H357",
      #         @access_token="01DVX6QBS3EG6FHY2ESAA5Q65X"
      #        >
      #
      # @return [WorkOS::Profile]
      def profile(code:, project_id:, redirect_uri:)
        query = Rack::Utils.build_query(
          client_id: project_id,
          client_secret: WorkOS.key!,
          redirect_uri: redirect_uri,
          grant_type: 'authorization_code',
          code: code,
        )

        request = Net::HTTP::Post.new("/sso/token?#{query}")
        response = client.request(request)

        WorkOS::Profile.new(response.body)
      end

      private

      sig { returns(Net::HTTP) }
      def client
        return @client if defined?(@client)

        @client = Net::HTTP.new(WorkOS::API_HOSTNAME, 443)
        @client.use_ssl = true

        @client
      end
    end
  end
end
