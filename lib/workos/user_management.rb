# frozen_string_literal: true
# typed: true

require 'net/http'
require 'uri'

module WorkOS
  # The UserManagement module provides convenience methods for working with the
  # WorkOS User platform. You'll need a valid API key.

  # rubocop:disable Metrics/ModuleLength
  module UserManagement
    module Types
      # The ProviderEnum is type-safe declaration of a
      # fixed set of values for User Management Providers.
      class Provider < T::Enum
        enums do
          Google = new('GoogleOAuth')
          Microsoft = new('MicrosoftOAuth')
          AuthKit = new('authkit')
        end
      end
    end

    class << self
      extend T::Sig
      include Client

      PROVIDERS = WorkOS::UserManagement::Types::Provider.values.map(&:serialize).freeze

      # Generate an OAuth 2.0 authorization URL that automatically directs a user
      # to their Identity Provider.
      #
      # @param [String] redirect_uri The URI where users are directed
      #  after completing the authentication step. Must match a
      #  configured redirect URI on your WorkOS dashboard.
      # @param [String] client_id This value can be obtained from the API Keys page in the WorkOS dashboard.
      # @param [String] provider A provider name is used to initiate SSO using an
      # OAuth-compatible provider. Only 'authkit ,'GoogleOAuth' and 'MicrosoftOAuth' are supported.
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
      sig do
        params(
          redirect_uri: String,
          client_id: T.nilable(String),
          domain_hint: T.nilable(String),
          login_hint: T.nilable(String),
          provider: T.nilable(String),
          connection_id: T.nilable(String),
          organization_id: T.nilable(String),
          state: T.nilable(String),
        ).returns(String)
      end
      def get_authorization_url(
        redirect_uri:,
        client_id: nil,
        domain_hint: nil,
        login_hint: nil,
        provider: nil,
        connection_id: nil,
        organization_id: nil,
        state: ''
      )

        validate_get_authorization_url_arguments(
          provider: provider,
          connection_id: connection_id,
          organization_id: organization_id,
        )

        query = URI.encode_www_form({
          client_id: client_id,
          redirect_uri: redirect_uri,
          response_type: 'code',
          state: state,
          domain_hint: domain_hint,
          login_hint: login_hint,
          provider: provider,
          connection_id: connection_id,
          organization_id: organization_id,
        }.compact)

        "https://#{WorkOS.config.api_hostname}/user_management/authorize?#{query}"
      end
      # rubocop:enable Metrics/ParameterLists

      # Adds a User as a member of the given Organization.
      #
      # @param [String] id The unique ID of the User.
      # @param [String] organization_id Unique identifier of the Organization.
      #
      # @return WorkOS::User
      sig do
        params(
          id: String,
          organization_id: String,
        ).returns(WorkOS::User)
      end
      def add_user_to_organization(id:, organization_id:)
        response = execute_request(
          request: post_request(
            path: "/users/#{id}/organizations",
            body: {
              organization_id: organization_id,
            },
            auth: true,
          ),
        )

        WorkOS::User.new(response.body)
      end


      # Deletes a User
      #
      # @param [String] id The unique ID of the User.
      #
      # @return [Bool] - returns `true` if successful
      sig do
        params(
          id: String,
        ).returns(T::Boolean)
      end
      def delete_user(id:)
        response = execute_request(
          request: delete_request(
            path: "/users/#{id}",
            auth: true,
          ),
        )

        response.is_a? Net::HTTPSuccess
      end

      # Resets user password using token that was sent to the user.
      #
      # @param [String] token The token that was sent to the user.
      # @param [String] new_password The new password to set for the user.
      #
      # @return WorkOS::User
      sig do
        params(
          token: String,
          new_password: String,
        ).returns(WorkOS::User)
      end
      def reset_password(token:, new_password:)
        response = execute_request(
          request: post_request(
            path: '/users/password_reset',
            body: {
              token: token,
              new_password: new_password,
            },
            auth: true,
          ),
        )

        WorkOS::User.new(response.body)
      end

      # Creates a password reset challenge and emails a password reset link to a user.
      #
      # @param [String] email The email of the user that wishes to reset their password.
      # @param [String] password_reset_url The URL that will be linked to in the email.
      #
      # @return WorkOS::UserAndToken
      sig do
        params(
          email: String,
          password_reset_url: String,
        ).returns(WorkOS::UserAndToken)
      end
      def send_password_reset_email(email:, password_reset_url:)
        request = post_request(
          path: '/users/send_password_reset_email',
          body: {
            email: email,
            password_reset_url: password_reset_url,
          },
          auth: true,
        )

        response = execute_request(request: request)

        WorkOS::UserAndToken.new(response.body)
      end

      # Create a user
      #
      # @param [String] email The email address of the user.
      # @param [String] password The password to set for the user.
      # @param [String] first_name The user's first name.
      # @param [String] last_name The user's last name.
      # @param [Boolean] email_verified Whether the user's email address was previously verified.
      sig do
        params(
          email: String,
          password: T.nilable(String),
          first_name: T.nilable(String),
          last_name: T.nilable(String),
          email_verified: T.nilable(T::Boolean),
        ).returns(WorkOS::User)
      end
      def create_user(email:, password: nil, first_name: nil, last_name: nil, email_verified: nil)
        request = post_request(
          path: '/users',
          body: {
            email: email,
            password: password,
            first_name: first_name,
            last_name: last_name,
            email_verified: email_verified,
          },
          auth: true,
        )

        response = execute_request(request: request)

        WorkOS::User.new(response.body)
      end


      # Update a user
      #
      # @param [String] id of the user.
      # @param [String] first_name The user's first name.
      # @param [String] last_name The user's last name.
      # @param [Boolean] email_verified Whether the user's email address was previously verified.
      sig do
        params(
          id: String,
          first_name: T.nilable(String),
          last_name: T.nilable(String),
          email_verified: T.nilable(T::Boolean),
        ).returns(WorkOS::User)
      end
      def update_user(id:, first_name: nil, last_name: nil, email_verified: nil)
        request = put_request(
          path: "/users/#{id}",
          body: {
            first_name: first_name,
            last_name: last_name,
            email_verified: email_verified,
          },
          auth: true,
        )

        response = execute_request(request: request)

        WorkOS::User.new(response.body)
      end

      sig do
        params(id: String).returns(WorkOS::User)
      end
      def get_user(id:)
        response = execute_request(
          request: get_request(
            path: "/users/#{id}",
            auth: true,
          ),
        )

        WorkOS::User.new(response.body)
      end

      # Retrieve a list of users.
      #
      # @param [Hash] options
      # @option options [String] email Filter Users by their email.
      # @option options [String] organization Filter Users by the organization
      #  they are members of.
      # @option options [String] limit Maximum number of records to return.
      # @option options [String] order The order in which to paginate records
      # @option options [String] before Pagination cursor to receive records
      #  before a provided User ID.
      # @option options [String] after Pagination cursor to receive records
      #  before a provided User ID.
      #
      # @return [WorkOS::User]
      sig do
        params(
          options: T::Hash[Symbol, String],
        ).returns(WorkOS::Types::ListStruct)
      end
      def list_users(options = {})
        response = execute_request(
          request: get_request(
            path: '/users',
            auth: true,
            params: options,
          ),
        )

        parsed_response = JSON.parse(response.body)

        users = parsed_response['data'].map do |user|
          ::WorkOS::User.new(user.to_json)
        end

        WorkOS::Types::ListStruct.new(
          data: users,
          list_metadata: parsed_response['list_metadata'],
        )
      end

      # Removes an unmanaged User from the given Organization.
      #
      # @param [String] id The unique ID of the User.
      # @param [String] organization_id Unique identifier of the Organization.
      #
      # @return WorkOS::User
      sig do
        params(
          id: String,
          organization_id: String,
        ).returns(WorkOS::User)
      end
      def remove_user_from_organization(id:, organization_id:)
        response = execute_request(
          request: delete_request(
            path: "/users/#{id}/organizations/#{organization_id}",
            auth: true,
          ),
        )

        WorkOS::User.new(response.body)
      end

      # Creates a one-time Magic Auth code and emails it to the user.
      #
      # @param [String] email_address The email address the one-time code will be sent to.
      #
      # @return WorkOS::UserResponse
      sig do
        params(
          email_address: String,
        ).returns(WorkOS::UserResponse)
      end
      def send_magic_auth_code(email_address:)
        response = execute_request(
          request: post_request(
            path: '/users/magic_auth/send',
            body: {
              email_address: email_address,
            },
            auth: true,
          ),
        )

        WorkOS::UserResponse.new(response.body)
      end

      # Sends a verification email to the provided user.
      #
      # @param [String] id The unique ID of the User whose email address will be verified.
      #
      # @return WorkOS::UserResponse
      sig do
        params(
          id: String,
        ).returns(WorkOS::UserResponse)
      end
      def send_verification_email(id:)
        response = execute_request(
          request: post_request(
            path: "/users/#{id}/send_verification_email",
            auth: true,
          ),
        )

        WorkOS::UserResponse.new(response.body)
      end

      # Verifies user email using one-time code that was sent to the user.
      #
      # @param [String] user_id The unique ID of the User whose email address will be verified.
      # @param [String] code The one-time code emailed to the user.
      #
      # @return WorkOS::UserResponse
      sig do
        params(
          user_id: String,
          code: String,
        ).returns(WorkOS::UserResponse)
      end
      def verify_email(user_id:, code:)
        response = execute_request(
          request: post_request(
            path: "/users/#{user_id}/verify_email_code",
            body: {
              code: code,
            },
            auth: true,
          ),
        )
        WorkOS::UserResponse.new(response.body)
      end

      # Updates user user password.
      #
      # @param [String] id The unique ID of the User.
      # @param [String] password The new password to set for the user.
      #
      # @return WorkOS::User

      sig do
        params(
          id: String,
          password: String,
        ).returns(WorkOS::User)
      end
      def update_user_password(id:, password:)
        response = execute_request(
          request: put_request(
            path: "/users/#{id}/password",
            body: {
              password: password,
            },
            auth: true,
          ),
        )

        WorkOS::User.new(response.body)
      end

      # Authenticates user by email and password.
      #
      # @param [String] email The email address of the user.
      # @param [String] password The password for the user.
      # @param [String] ip_address The IP address of the request from the user who is attempting to authenticate.
      # @param [String] user_agent The user agent of the request from the user who is attempting to authenticate.
      # @param [String] client_id The WorkOS client ID for the environment
      #
      # @return WorkOS::UserResponse

      sig do
        params(
          email: String,
          password: String,
          client_id: String,
          ip_address: T.nilable(String),
          user_agent: T.nilable(String),
        ).returns(WorkOS::UserResponse)
      end
      def authenticate_user_password(email:, password:, client_id:, ip_address: nil, user_agent: nil)
        response = execute_request(
          request: post_request(
            path: '/users/authenticate',
            body: {
              client_id: client_id,
              client_secret: WorkOS.config.key!,
              email: email,
              password: password,
              ip_address: ip_address,
              user_agent: user_agent,
              grant_type: 'password',
            },
          ),
        )
        WorkOS::UserResponse.new(response.body)
      end

      # Authenticates user by Magic Auth Code.
      #
      # @param [String] code The one-time code that was emailed to the user.
      # @param [String] user_id The unique ID of the User who will be authenticated.
      # @param [String] client_id The WorkOS client ID for the environment.
      # @param [String] ip_address The IP address of the request from the user who is attempting to authenticate.
      # @param [String] user_agent The user agent of the request from the user who is attempting to authenticate.
      #
      # @return WorkOS::UserResponse

      sig do
        params(
          code: String,
          user_id: String,
          client_id: String,
          ip_address: T.nilable(String),
          user_agent: T.nilable(String),
        ).returns(WorkOS::UserResponse)
      end
      def authenticate_user_magic_auth(code:, user_id:, client_id:, ip_address: nil, user_agent: nil)
        response = execute_request(
          request: post_request(
            path: '/users/authenticate',
            body: {
              code: code,
              user_id: user_id,
              client_id: client_id,
              client_secret: WorkOS.config.key!,
              ip_address: ip_address,
              user_agent: user_agent,
              grant_type: 'urn:workos:oauth:grant-type:magic-auth:code',
            },
          ),
        )
        WorkOS::UserResponse.new(response.body)
      end

      # Authenticates a user using OAuth code.
      #
      # @param [String] code The one-time code that was emailed to the user.
      # @param [String] client_id The WorkOS client ID for the environment
      # @param [String] ip_address The IP address of the request from the user who is attempting to authenticate.
      # @param [String] user_agent The user agent of the request from the user who is attempting to authenticate.
      #
      # @return WorkOS::UserResponse

      sig do
        params(
          code: String,
          client_id: String,
          ip_address: T.nilable(String),
          user_agent: T.nilable(String),
        ).returns(WorkOS::UserResponse)
      end
      def authenticate_user_with_code(code:, client_id:, ip_address: nil, user_agent: nil)
        response = execute_request(
          request: post_request(
            path: '/users/authenticate',
            body: {
              code: code,
              client_id: client_id,
              client_secret: WorkOS.config.key!,
              ip_address: ip_address,
              user_agent: user_agent,
              grant_type: 'authorization_code',
            },
          ),
        )
        WorkOS::UserResponse.new(response.body)
      end

      #
      # Authenticates a user using TOTP.
      #
      # @param [String] code The one-time code that was emailed to the user.
      # @param [String] client_id The WorkOS client ID for the environment
      # @param [String] pending_authentication_token The pending authentication token
      # from the initial authentication request.
      # @param [String] authentication_challenge_id The authentication challenge ID for the
      # authentication request.
      #
      # @return WorkOS::UserResponse

      sig do
        params(
          code: String,
          client_id: String,
          pending_authentication_token: String,
          authentication_challenge_id: String,
        ).returns(WorkOS::UserResponse)
      end
      def authenticate_user_with_totp(code:, client_id:, pending_authentication_token:, authentication_challenge_id:)
        response = execute_request(
          request: post_request(
            path: '/users/authenticate',
            body: {
              code: code,
              client_id: client_id,
              client_secret: WorkOS.config.key!,
              pending_authentication_token: pending_authentication_token,
              authentication_challenge_id: authentication_challenge_id,
              grant_type: 'urn:workos:oauth:grant-type:mfa-totp',
            },
          ),
        )
        WorkOS::UserResponse.new(response.body)
      end

      # Enroll a user into an authentication factor.
      #
      # @param [String] user_id The id for the user.
      #
      # @return WorkOS::AuthenticationFactorAndChallenge
      sig do
        params(
          user_id: String,
        ).returns(WorkOS::AuthenticationFactorAndChallenge)
      end
      def enroll_auth_factor(user_id:)
        response = execute_request(
          request: post_request(
            path: "/users/#{user_id}/auth/factors",
            body: {
              type: 'totp',
            },
            auth: true,
          ),
        )

        WorkOS::AuthenticationFactorAndChallenge.new(response.body)
      end

      # Get all auth factors for a user
      #
      # @param [String] user_id The id for the user.
      #
      # @return WorkOS::ListStruct
      sig do
        params(
          user_id: String,
        ).returns(WorkOS::Types::ListStruct)
      end
      def list_auth_factors(user_id:)
        response = execute_request(
          request: get_request(
            path: "/users/#{user_id}/auth/factors",
            auth: true,
          ),
        )

        parsed_response = JSON.parse(response.body)

        auth_factors = parsed_response['data'].map do |auth_factor|
          ::WorkOS::Factor.new(auth_factor.to_json)
        end

        WorkOS::Types::ListStruct.new(
          data: auth_factors,
          list_metadata: parsed_response['list_metadata'],
        )
      end

      private

      sig do
        params(
          provider: T.nilable(String),
          connection_id: T.nilable(String),
          organization_id: T.nilable(String),
        ).void
      end

      def validate_get_authorization_url_arguments(
        provider:,
        connection_id:,
        organization_id:
      )
        if [provider, connection_id, organization_id].all?(&:nil?)
          raise ArgumentError, 'Either connection ID, organization ID,' \
            ' or provider is required.'
        end

        return unless provider && !PROVIDERS.include?(provider)

        raise ArgumentError, "#{provider} is not a valid value." \
          " `provider` must be in #{PROVIDERS}"
      end
    end
  end
  # rubocop:enable Metrics/ModuleLength
end
