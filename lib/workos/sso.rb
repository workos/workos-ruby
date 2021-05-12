# frozen_string_literal: true
# typed: true

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
      extend T::Sig
      include Base
      include Client

      PROVIDERS = WorkOS::Types::Provider.values.map(&:serialize).freeze

      # Generate an Oauth2 authorization URL where your users will
      # authenticate using the configured SSO Identity Provider.
      #
      # @param [String] domain The domain for the relevant SSO Connection
      #  configured on your WorkOS dashboard. One of provider or domain is
      #  required
      # @param [String] provider A provider name for an Identity Provider
      #  configured on your WorkOS dashboard. Only 'Google' is supported.
      # @param [String] connection The ID for a Connection configured on
      #  WorkOS.
      # @param [String] client_id The WorkOS client ID for the environment
      #  where you've configured your SSO connection.
      # @param [String] redirect_uri The URI where users are directed
      #  after completing the authentication step. Must match a
      #  configured redirect URI on your WorkOS dashboard.
      # @param [String] state An aribtrary state object
      #  that is preserved and available to the client in the response.
      # @example
      #   WorkOS::SSO.authorization_url(
      #     domain: 'acme.com',
      #     client_id: 'project_01DG5TGK363GRVXP3ZS40WNGEZ',
      #     redirect_uri: 'https://workos.com/callback',
      #     state: {
      #       next_page: '/docs'
      #     }.to_s
      #   )
      #
      #   => "https://api.workos.com/sso/authorize?domain=acme.com" \
      #      "&client_id=project_01DG5TGK363GRVXP3ZS40WNGEZ" \
      #      "&redirect_uri=https%3A%2F%2Fworkos.com%2Fcallback&" \
      #      "response_type=code&state=%7B%3Anext_page%3D%3E%22%2Fdocs%22%7D"
      #
      # @return [String]
      sig do
        params(
          redirect_uri: String,
          client_id: T.nilable(String),
          domain: T.nilable(String),
          provider: T.nilable(String),
          connection: T.nilable(String),
          state: T.nilable(String),
        ).returns(String)
      end
      def authorization_url(
        redirect_uri:,
        client_id: nil,
        domain: nil,
        provider: nil,
        connection: nil,
        state: ''
      )
        validate_authorization_url_arguments(
          provider: provider,
          domain: domain,
          connection: connection,
        )

        query = URI.encode_www_form({
          client_id: client_id,
          redirect_uri: redirect_uri,
          response_type: 'code',
          state: state,
          domain: domain,
          provider: provider,
          connection: connection,
        }.compact)

        "https://#{WorkOS::API_HOSTNAME}/sso/authorize?#{query}"
      end

      # Fetch the profile details for the authenticated SSO user.
      #
      # @param [String] code The authorization code provided in the callback URL
      # @param [String] client_id The WorkOS client ID for the environment
      #  where you've configured your SSO connection
      #
      # @example
      #   WorkOS::SSO.profile_and_token(
      #     code: 'acme.com',
      #     client_id: 'project_01DG5TGK363GRVXP3ZS40WNGEZ'
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
      # @return [WorkOS::ProfileAndToken]
      sig do
        params(
          code: String,
          client_id: T.nilable(String),
        ).returns(WorkOS::ProfileAndToken)
      end
      def profile_and_token(code:, client_id: nil)
        body = {
          client_id: client_id,
          client_secret: WorkOS.key!,
          grant_type: 'authorization_code',
          code: code,
        }

        response = client.request(post_request(path: '/sso/token', body: body))
        check_and_raise_profile_and_token_error(response: response)

        WorkOS::ProfileAmdTplem.new(response.body)
      end

      # Promote a DraftConnection created via the WorkOS.js embed such that the
      # Enterprise users can begin signing into your application.
      #
      # @param [String] token The Draft Connection token that's been provided to
      # you by the WorkOS.js
      #
      # @example
      #   WorkOS::SSO.promote_draft_connection(
      #     token: 'draft_conn_429u59js',
      #   )
      #   => true
      #
      # @return [Bool] - returns `true` if successful, `false` otherwise.
      # @see https://github.com/workos-inc/ruby-idp-link-example
      sig { params(token: String).returns(T::Boolean) }
      def promote_draft_connection(token:)
        request = post_request(
          auth: true,
          path: "/draft_connections/#{token}/activate",
        )

        response = client.request(request)

        response.is_a? Net::HTTPSuccess
      end

      # Create a Connection
      #
      # @param [String] source The Draft Connection token that's been provided
      # to you by WorkOS.js
      #
      # @example
      #   WorkOS::SSO.create_connection(source: 'draft_conn_429u59js')
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
      sig { params(source: String).returns(WorkOS::Connection) }
      def create_connection(source:)
        request = post_request(
          auth: true,
          path: '/connections',
          body: { source: source },
        )

        response = execute_request(request: request)

        WorkOS::Connection.new(response.body)
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
      # @option options [String] before Pagination cursor to receive records
      #  before a provided Connection ID.
      # @option options [String] after Pagination cursor to receive records
      #  before a provided Connection ID.
      #
      # @return [Hash]
      sig do
        params(
          options: T::Hash[Symbol, String],
        ).returns(WorkOS::Types::ListStruct)
      end
      def list_connections(options = {})
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
      sig { params(id: String).returns(WorkOS::Connection) }
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
      sig { params(id: String).returns(T::Boolean) }
      def delete_connection(id:)
        request = delete_request(
          auth: true,
          path: "/connections/#{id}",
        )

        response = execute_request(request: request)

        response.is_a? Net::HTTPSuccess
      end

      private

      sig do
        params(
          domain: T.nilable(String),
          provider: T.nilable(String),
          connection: T.nilable(String),
        ).void
      end
      def validate_authorization_url_arguments(
        domain:,
        provider:,
        connection:
      )
        if [domain, provider, connection].all?(&:nil?)
          raise ArgumentError, 'Either connection, domain, or ' \
            'provider is required.'
        end

        return unless provider && !PROVIDERS.include?(provider)

        raise ArgumentError, "#{provider} is not a valid value." \
          " `provider` must be in #{PROVIDERS}"
      end

      sig { params(response: Net::HTTPResponse).void }
      def check_and_raise_profile_and_token_error(response:)
        begin
          body = JSON.parse(response.body)
          return if body['access_token'] && body['profile']

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
    end
  end
end
