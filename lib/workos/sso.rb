# frozen_string_literal: true

require 'net/http'
require 'uri'

module WorkOS
  # The SSO module provides convenience methods for working with the WorkOS
  # SSO platform. You'll need a valid API key, a client ID, and to have
  # created an SSO connection on your WorkOS dashboard.
  #
  # @see https://docs.workos.com/sso/overview
  module SSO
    class << self
      include Client, Deprecation

      PROVIDERS = WorkOS::Types::Provider::ALL

      # Generate an Oauth2 authorization URL where your users will
      # authenticate using the configured SSO Identity Provider.
      #
      # @param [String] redirect_uri The URI where users are directed
      #  after completing the authentication step. Must match a
      #  configured redirect URI on your WorkOS dashboard.
      # @param [String] client_id The WorkOS client ID for the environment
      #  where you've configured your SSO connection.
      # @param [String] domain The domain for the relevant SSO Connection
      #  configured on your WorkOS dashboard. One of provider, domain,
      #  connection, or organization is required.
      #  The domain is deprecated.
      # @param [String] provider A provider name for an Identity Provider
      #  configured on your WorkOS dashboard. Only 'GoogleOAuth',
      #  'MicrosoftOAuth', 'GithubOAuth', and 'AppleOAuth' are supported.
      # @param [String] connection The ID for a Connection configured on
      #  WorkOS.
      # @param [String] organization The ID for an Organization configured
      #  on WorkOS.
      # @param [String] state An arbitrary state object
      #  that is preserved and available to the client in the response.
      # @example
      #   WorkOS::SSO.authorization_url(
      #     connection: 'conn_123',
      #     client_id: 'project_01DG5TGK363GRVXP3ZS40WNGEZ',
      #     redirect_uri: 'https://workos.com/callback',
      #     state: {
      #       next_page: '/docs'
      #     }.to_s
      #   )
      #
      #   => "https://api.workos.com/sso/authorize?connection=conn_123" \
      #      "&client_id=project_01DG5TGK363GRVXP3ZS40WNGEZ" \
      #      "&redirect_uri=https%3A%2F%2Fworkos.com%2Fcallback&" \
      #      "response_type=code&state=%7B%3Anext_page%3D%3E%22%2Fdocs%22%7D"
      #
      # @return [String]
      # rubocop:disable Metrics/ParameterLists
      def authorization_url(
        redirect_uri:,
        client_id: nil,
        domain: nil,
        domain_hint: nil,
        login_hint: nil,
        provider: nil,
        connection: nil,
        organization: nil,
        state: ''
      )
        if domain
          warn_deprecation '[DEPRECATION] `domain` is deprecated.
          Please use `organization` instead.'
        end

        validate_authorization_url_arguments(
          provider: provider,
          domain: domain,
          connection: connection,
          organization: organization,
        )

        query = URI.encode_www_form({
          client_id: client_id,
          redirect_uri: redirect_uri,
          response_type: 'code',
          state: state,
          domain: domain,
          domain_hint: domain_hint,
          login_hint: login_hint,
          provider: provider,
          connection: connection,
          organization: organization,
        }.compact)

        "https://#{WorkOS.config.api_hostname}/sso/authorize?#{query}"
      end
      # rubocop:enable Metrics/ParameterLists

      def get_profile(access_token:)
        response = execute_request(
          request: get_request(
            path: '/sso/profile',
            auth: true,
            access_token: access_token,
          ),
        )

        WorkOS::Profile.new(response.body)
      end

      # Fetch the profile details for the authenticated SSO user.
      #
      # @param [String] code The authorization code provided in the callback URL
      # @param [String] client_id The WorkOS client ID for the environment
      #  where you've configured your SSO connection
      #
      # @return [WorkOS::ProfileAndToken]
      def profile_and_token(code:, client_id: nil)
        body = {
          client_id: client_id,
          client_secret: WorkOS.config.key!,
          grant_type: 'authorization_code',
          code: code,
        }

        response = client.request(post_request(path: '/sso/token', body: body))
        check_and_raise_profile_and_token_error(response: response)

        WorkOS::ProfileAndToken.new(response.body)
      end

      # Retrieve connections.
      #
      # @param [Hash] options An options hash
      # @option options [String] connection_type Authentication service
      #  provider descriptor.
      # @option options [String] domain The domain of the connection to be
      #  retrieved.
      # @option options [String] organization_id The id of the organization
      #  of the connections to be retrieved.
      # @option options [String] limit Maximum number of records to return.
      # @option options [String] order The order in which to paginate records
      # @option options [String] before Pagination cursor to receive records
      #  before a provided Connection ID.
      # @option options [String] after Pagination cursor to receive records
      #  before a provided Connection ID.
      #
      # @return [Hash]
      def list_connections(options = {})
        options[:order] ||= 'desc'
        response = execute_request(
          request: get_request(
            path: '/connections',
            auth: true,
            params: options,
          ),
        )

        parsed_response = JSON.parse(response.body)
        connections = parsed_response['data'].map do |connection|
          ::WorkOS::Connection.new(connection.to_json)
        end

        WorkOS::Types::ListStruct.new(
          data: connections,
          list_metadata: parsed_response['listMetadata'],
        )
      end

      # Get a Connection
      #
      # @param [String] id Connection unique identifier
      #
      # @example
      #   WorkOS::SSO.get_connection(id: 'conn_02DRA1XNSJDZ19A31F183ECQW9')
      #   => #<WorkOS::Connection:0x00007fb6e4193d20
      #         @id="conn_02DRA1XNSJDZ19A31F183ECQW9",
      #         @name="Foo Corp",
      #         @connection_type="OktaSAML",
      #         @domains=
      #          [{:object=>"connection_domain",
      #            :id=>"domain_01E6PK9N3XMD8RHWF7S66380AR",
      #            :domain=>"example.com"}]>
      #
      # @return [WorkOS::Connection]
      def get_connection(id:)
        request = get_request(
          auth: true,
          path: "/connections/#{id}",
        )

        response = execute_request(request: request)

        WorkOS::Connection.new(response.body)
      end

      # Delete a Connection
      #
      # @param [String] id Connection unique identifier
      #
      # @example
      #   WorkOS::SSO.delete_connection(id: 'conn_02DRA1XNSJDZ19A31F183ECQW9')
      #   => true
      #
      # @return [Bool] - returns `true` if successful
      def delete_connection(id:)
        request = delete_request(
          auth: true,
          path: "/connections/#{id}",
        )

        response = execute_request(request: request)

        response.is_a? Net::HTTPSuccess
      end

      private

      def validate_authorization_url_arguments(
        domain:,
        provider:,
        connection:,
        organization:
      )
        if [domain, provider, connection, organization].all?(&:nil?)
          raise ArgumentError, 'Either connection, domain, ' \
            'provider, or organization is required.'
        end

        return unless provider && !PROVIDERS.include?(provider)

        raise ArgumentError, "#{provider} is not a valid value." \
          " `provider` must be in #{PROVIDERS}"
      end

      def check_and_raise_profile_and_token_error(response:)
        begin
          body = JSON.parse(response.body)
          return if body['access_token'] && body['profile']

          message = body['message']
          error = body['error']
          error_description = body['error_description']
          request_id = response['x-request-id']
        rescue StandardError
          message = 'Something went wrong'
        end

        raise APIError.new(
          message: message,
          error: error,
          error_description: error_description,
          http_status: nil,
          request_id: request_id,
        )
      end
    end
  end
end
