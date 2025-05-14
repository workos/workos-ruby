# frozen_string_literal: true

require 'net/http'
require 'uri'

module WorkOS
  # The UserManagement module provides convenience methods for working with the
  # WorkOS User platform. You'll need a valid API key.

  # rubocop:disable Metrics/ModuleLength
  module UserManagement
    module Types
      # The ProviderEnum is a declaration of a
      # fixed set of values for User Management Providers.
      class Provider
        Apple = 'AppleOAuth'
        GitHub = 'GitHubOAuth'
        Google = 'GoogleOAuth'
        Microsoft = 'MicrosoftOAuth'
        AuthKit = 'authkit'

        ALL = [Apple, GitHub, Google, Microsoft, AuthKit].freeze
      end

      # The AuthFactorType is a declaration of a
      # fixed set of factor values to enroll
      class AuthFactorType
        Totp = 'totp'

        ALL = [Totp].freeze
      end
    end

    class << self
      include Client, Deprecation

      PROVIDERS = WorkOS::UserManagement::Types::Provider::ALL
      AUTH_FACTOR_TYPES = WorkOS::UserManagement::Types::AuthFactorType::ALL

      # Load a sealed session
      #
      # @param [String] client_id The WorkOS client ID for the environment
      # @param [String] session_data The sealed session data
      # @param [String] cookie_password The password used to seal the session
      #
      # @return WorkOS::Session
      def load_sealed_session(client_id:, session_data:, cookie_password:)
        WorkOS::Session.new(
          user_management: self,
          client_id: client_id,
          session_data: session_data,
          cookie_password: cookie_password,
        )
      end

      # Generate an OAuth 2.0 authorization URL that automatically directs a user
      # to their Identity Provider.
      #
      # @param [String] redirect_uri The URI where users are directed
      #  after completing the authentication step. Must match a
      #  configured redirect URI on your WorkOS dashboard.
      # @param [String] client_id This value can be obtained from the API Keys page in the WorkOS dashboard.
      # @param [String] provider A provider name is used to initiate SSO using an
      # OAuth-compatible provider. Only 'authkit', 'AppleOAuth', 'GitHubOAuth', 'GoogleOAuth',
      # and 'MicrosoftOAuth' are supported.
      # @param [String] connection_id The ID for a Connection configured on
      #  WorkOS.
      # @param [String] organization_id The organization_id selector is used to
      # initiate SSO for an Organization.
      # @param [String] state An arbitrary state object
      #  that is preserved and available to the client in the response.
      # @param [String] login_hint Can be used to pre-fill the username/email address
      # field of the IdP sign-in page for the user, if you know their username ahead of time.
      # @param [String] domain_hint Can be used to pre-fill the domain field when
      # initiating authentication with Microsoft OAuth, or with a GoogleSAML connection type.
      # @param [String] email The email of the user to be updated.
      # @example
      #   WorkOS::UserManagement.authorization_url(
      #     connection_id: 'conn_123',
      #     client_id: 'project_01DG5TGK363GRVXP3ZS40WNGEZ',
      #     redirect_uri: 'https://your-app.com/callback',
      #     state: {
      #       next_page: '/docs'
      #     }.to_s
      #   )
      #
      #   => "https://api.workos.com/user_management/authorize?connection_id=conn_123" \
      #      "&client_id=project_01DG5TGK363GRVXP3ZS40WNGEZ" \
      #      "&redirect_uri=https%3A%2F%2Fyour-app.com%2Fcallback&" \
      #      "response_type=code&state=%7B%3Anext_page%3D%3E%22%2Fdocs%22%7D"
      #
      # @return [String]
      # rubocop:disable Metrics/ParameterLists
      def authorization_url(
        redirect_uri:,
        client_id: nil,
        domain_hint: nil,
        login_hint: nil,
        provider: nil,
        connection_id: nil,
        email: nil,