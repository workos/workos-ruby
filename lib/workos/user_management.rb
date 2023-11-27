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

      # The AuthFactorType is type-safe declaration of a
      # fixed set of factor values to enroll
      class AuthFactorType < T::Enum
        enums do
          Totp = new('totp')
        end
      end
    end

    class << self
      extend T::Sig
      include Client

      PROVIDERS = WorkOS::UserManagement::Types::Provider.values.map(&:serialize).freeze
      AUTH_FACTOR_TYPES = WorkOS::UserManagement::Types::AuthFactorType.values.map(&:serialize).freeze

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
      def authorization_url(
        redirect_uri:,
        client_id: nil,
        domain_hint: nil,
        login_hint: nil,
        provider: nil,
        connection_id: nil,
        organization_id: nil,
        state: ''
      )

        validate_authorization_url_arguments(
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

      # Gets a User
      #
      # @param [String] id The unique ID of the User.
      #
      # @return WorkOS::User
      sig do
        params(id: String).returns(WorkOS::User)
      end
      def get_user(id:)
        response = execute_request(
          request: get_request(
            path: "/user_management/users/#{id}",
            auth: true,
          ),
        )

        WorkOS::User.new(response.body)
      end

      # Retrieve a list of users.
      #
      # @param [Hash] options
      # @option options [String] email Filter Users by their email.
      # @option options [String] organization_id Filter Users by the organization they are members of.
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
            path: '/user_management/users',
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
          path: '/user_management/users',
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
          path: "/user_management/users/#{id}",
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
            path: "/user_management/users/#{id}",
            auth: true,
          ),
        )

        response.is_a? Net::HTTPSuccess
      end

      # Authenticates user by email and password.
      #
      # @param [String] email The email address of the user.
      # @param [String] password The password for the user.
      # @param [String] client_id The WorkOS client ID for the environment
      # @param [String] ip_address The IP address of the request from the user who is attempting to authenticate.
      # @param [String] user_agent The user agent of the request from the user who is attempting to authenticate.
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
      def authenticate_with_password(email:, password:, client_id:, ip_address: nil, user_agent: nil)
        response = execute_request(
          request: post_request(
            path: '/user_management/authenticate',
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

      # Authenticate a user using OAuth or an organization's SSO connection.
      #
      # @param [String] code The authorization value which was passed back as a
      # query parameter in the callback to the Redirect URI.
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
      def authenticate_with_code(
        code:,
        client_id:,
        ip_address: nil,
        user_agent: nil
      )
        response = execute_request(
          request: post_request(
            path: '/user_management/authenticate',
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

      # Authenticates user by Magic Auth Code.
      #
      # @param [String] code The one-time code that was emailed to the user.
      # @param [String] user_id The unique ID of the User who will be authenticated.
      # @param [String] client_id The WorkOS client ID for the environment.
      # @param [String] ip_address The IP address of the request from the user who is attempting to authenticate.
      # @param [String] link_authorization_code Used to link an OAuth profile to an existing user,
      # after having completed a Magic Code challenge.
      # @param [String] user_agent The user agent of the request from the user who is attempting to authenticate.
      #
      # @return WorkOS::UserResponse

      sig do
        params(
          code: String,
          email: String,
          client_id: String,
          ip_address: T.nilable(String),
          user_agent: T.nilable(String),
          link_authorization_code: T.nilable(String),
        ).returns(WorkOS::UserResponse)
      end
      def authenticate_with_magic_auth(
        code:,
        email:,
        client_id:,
        ip_address: nil,
        user_agent: nil,
        link_authorization_code: nil
      )
        response = execute_request(
          request: post_request(
            path: '/user_management/authenticate',
            body: {
              code: code,
              email: email,
              client_id: client_id,
              client_secret: WorkOS.config.key!,
              ip_address: ip_address,
              user_agent: user_agent,
              grant_type: 'urn:workos:oauth:grant-type:magic-auth:code',
              link_authorization_code: link_authorization_code,
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
      # @param [String] ip_address The IP address of the request from the user who is attempting to authenticate.
      # @param [String] user_agent The user agent of the request from the user who is attempting to authenticate.
      #
      # @return WorkOS::UserResponse

      sig do
        params(
          code: String,
          client_id: String,
          pending_authentication_token: String,
          authentication_challenge_id: String,
          ip_address: T.nilable(String),
          user_agent: T.nilable(String),
        ).returns(WorkOS::UserResponse)
      end
      def authenticate_with_totp(
        code:,
        client_id:,
        pending_authentication_token:,
        authentication_challenge_id:,
        ip_address: nil,
        user_agent: nil
      )
        response = execute_request(
          request: post_request(
            path: '/user_management/authenticate',
            body: {
              code: code,
              client_id: client_id,
              client_secret: WorkOS.config.key!,
              pending_authentication_token: pending_authentication_token,
              grant_type: 'urn:workos:oauth:grant-type:mfa-totp',
              authentication_challenge_id: authentication_challenge_id,
              ip_address: ip_address,
              user_agent: user_agent,
            },
          ),
        )

        WorkOS::UserResponse.new(response.body)
      end

      #
      # Authenticates a user using Email Verification Code.
      #
      # @param [String] code The one-time code that was emailed to the user.
      # @param [String] client_id The WorkOS client ID for the environment
      # @param [String] pending_authentication_token The token returned from a failed email/password or OAuth
      # authentication attempt due to an unverified email address.
      # @param [String] ip_address The IP address of the request from the user who is attempting to authenticate.
      # @param [String] user_agent The user agent of the request from the user who is attempting to authenticate.
      #
      # @return WorkOS::UserResponse

      sig do
        params(
          code: String,
          client_id: String,
          pending_authentication_token: String,
          ip_address: T.nilable(String),
          user_agent: T.nilable(String),
        ).returns(WorkOS::UserResponse)
      end
      def authenticate_with_email_verification(
        code:,
        client_id:,
        pending_authentication_token:,
        ip_address: nil,
        user_agent: nil
      )
        response = execute_request(
          request: post_request(
            path: '/user_management/authenticate',
            body: {
              code: code,
              client_id: client_id,
              pending_authentication_token: pending_authentication_token,
              client_secret: WorkOS.config.key!,
              grant_type: 'urn:workos:oauth:grant-type:email-verification:code',
              ip_address: ip_address,
              user_agent: user_agent,
            },
          ),
        )

        WorkOS::UserResponse.new(response.body)
      end

      # Creates a one-time Magic Auth code and emails it to the user.
      #
      # @param [String] email The email address the one-time code will be sent to.
      #
      # @return WorkOS::UserResponse
      sig do
        params(
          email: String,
        ).returns(WorkOS::UserResponse)
      end
      def send_magic_auth_code(email:)
        response = execute_request(
          request: post_request(
            path: '/user_management/magic_auth/send',
            body: {
              email: email,
            },
            auth: true,
          ),
        )

        WorkOS::UserResponse.new(response.body)
      end

      # Enroll a user into an authentication factor.
      #
      # @param [String] user_id The id for the user.
      # @param [String] type The type of the factor to enroll. Only option available is totp.
      # @param [String] totp_issuer For totp factors. Typically your application
      #  or company name, this helps users distinguish between factors in authenticator apps.
      # @param [String] totp_user For totp factors. Used as the account name in authenticator apps.
      #
      # @return WorkOS::AuthenticationFactorAndChallenge
      sig do
        params(
          user_id: String,
          type: String,
          totp_issuer: T.nilable(String),
          totp_user: T.nilable(String),
        ).returns(WorkOS::AuthenticationFactorAndChallenge)
      end
      def enroll_auth_factor(user_id:, type:, totp_issuer: nil, totp_user: nil)
        validate_auth_factor_type(
          type: type,
        )

        response = execute_request(
          request: post_request(
            path: "/user_management/users/#{user_id}/auth_factors",
            body: {
              type: type,
              totp_issuer: totp_issuer,
              totp_user: totp_user,
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
            path: "/user_management/users/#{user_id}/auth_factors",
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
            path: "/user_management/users/#{id}/email_verification/send",
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
            path: "/user_management/users/#{user_id}/email_verification/confirm",
            body: {
              code: code,
            },
            auth: true,
          ),
        )

        WorkOS::UserResponse.new(response.body)
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

      private

      sig do
        params(
          provider: T.nilable(String),
          connection_id: T.nilable(String),
          organization_id: T.nilable(String),
        ).void
      end

      def validate_authorization_url_arguments(
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

      sig do
        params(
          type: String,
        ).void
      end

      def validate_auth_factor_type(
        type:
      )
        return if AUTH_FACTOR_TYPES.include?(type)

        raise ArgumentError, "#{type} is not a valid value." \
          " `type` must be in #{AUTH_FACTOR_TYPES}"
      end
    end
  end
  # rubocop:enable Metrics/ModuleLength
end
