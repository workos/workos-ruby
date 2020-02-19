# frozen_string_literal: true
# typed: true

require 'net/http'
require 'uri'

module WorkOS
  # The SSO module provides convenience methods for working with the WorkOS
  # SSO platform. You'll need a valid API key, a project ID, and to have
  # created an SSO connection on your WorkOS dashboard.
  #
  # @see https://dashboard.workos.com/docs/sso/what-is-sso
  module SSO
    class << self
      extend T::Sig
      include Base
      include Client

      PROVIDERS = WorkOS::Types::Provider.values.map(&:serialize).freeze

      sig do
        params(
          project_id: String,
          redirect_uri: String,
          domain: T.nilable(String),
          provider: T.nilable(String),
          state: Hash,
        ).returns(String)
      end

      # Generate an Oauth2 authorization URL where your users will
      # authenticate using the configured SSO Identity Provider.
      #
      # @param [String] domain The domain for the relevant SSO Connection
      #  configured on your WorkOS dashboard. One of provider or domain is
      #  required
      # @param [String] provider A provider name for an Identity Provider
      #  configured on your WorkOS dashboard. Only 'Google' is supported.
      # @param [String] project_id The WorkOS project ID for the project
      #  where you've configured your SSO connection.
      # @param [String] redirect_uri The URI where users are directed
      #  after completing the authentication step. Must match a
      #  configured redirect URI on your WorkOS dashboard.
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
      def authorization_url(
        project_id:, redirect_uri:, domain: nil, provider: nil, state: {}
      )
        validate_domain_and_provider(provider: provider, domain: domain)

        query = URI.encode_www_form({
          client_id: project_id,
          redirect_uri: redirect_uri,
          response_type: 'code',
          state: state,
          domain: domain,
          provider: provider,
        }.compact)

        "https://#{WorkOS::API_HOSTNAME}/sso/authorize?#{query}"
      end

      sig do
        params(
          code: String,
          project_id: String,
        ).returns(WorkOS::Profile)
      end

      # Fetch the profile details for the authenticated SSO user.
      #
      # @param [String] code The authorization code provided in the callback URL
      # @param [String] project_id The WorkOS project ID for the project
      #  where you've  configured your SSO connection
      #
      # @example
      #   WorkOS::SSO.profile(
      #     code: 'acme.com',
      #     project_id: 'project_01DG5TGK363GRVXP3ZS40WNGEZ'
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
      def profile(code:, project_id:)
        query = URI.encode_www_form(
          client_id: project_id,
          client_secret: WorkOS.key!,
          grant_type: 'authorization_code',
          code: code,
        )

        response = client.request(post_request(path: "/sso/token?#{query}"))
        check_and_raise_profile_error(response: response)

        WorkOS::Profile.new(response.body)
      end

      # Promote a DraftConnection created via IdP Link Embed such that the
      # Enterprise users can begin signing into your application.
      #
      # @param [String] token The draft connection token that's been provided to
      # you by the IdP Link Embed
      #
      # @example
      #   WorkOS::SSO.promote_draft_connection(
      #     token: 'draft_conn_429u59js',
      #   )
      #   => true
      #
      # @return [Bool] - returns `true` if successful, `false` otherwise.
      # @see https://github.com/workos-inc/idp-link
      sig do
        params(
          token: String,
        ).returns(T::Boolean)
      end
      def promote_draft_connection(token:)
        request = bearer_post_request(
          path: '/draft_connections/convert',
          body: { id: token },
        )

        response = client.request(request)

        response.is_a? Net::HTTPSuccess
      end

      private

      sig do
        params(
          domain: T.nilable(String),
          provider: T.nilable(String),
        ).void
      end
      def validate_domain_and_provider(domain:, provider:)
        if [domain, provider].all?(&:nil?)
          raise ArgumentError, 'Either domain or provider is required.'
        end

        return unless provider && !PROVIDERS.include?(provider)

        raise ArgumentError, "#{provider} is not a valid value." \
          " `provider` must be in #{PROVIDERS}"
      end

      # rubocop:disable Metrics/MethodLength
      sig { params(response: Net::HTTPResponse).void }
      def check_and_raise_profile_error(response:)
        begin
          body = JSON.parse(response.body)
          return if body['profile']

          message = body['message']
          request_id = response['x-request-id']
        rescue StandardError
          message = 'Something went wrong'
        end

        raise APIError.new(
          message: message,
          http_status: nil,
          request_id: request_id,
        )
      end
      # rubocop:enable Metrics/MethodLength

      def bearer_post_request(path:, body: nil)
        request = post_request(path: path, body: body)
        request['Authorization'] = "Bearer #{WorkOS.key!}"
        request
      end
    end
  end
end
