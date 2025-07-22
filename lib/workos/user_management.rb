# frozen_string_literal: true

require 'net/http'
require 'uri'

module WorkOS
  # The UserManagement module provides convenience methods for working with the
  # WorkOS User platform. You'll need a valid API key.
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
      # @param [Array<String>] provider_scopes An array of additional OAuth scopes to request from the provider.
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
        organization_id: nil,
        state: '',
        provider_scopes: nil
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
          provider_scopes: provider_scopes,
        }.compact)

        "https://#{WorkOS.config.api_hostname}/user_management/authorize?#{query}"
      end
      # rubocop:enable Metrics/ParameterLists

      # Get a User
      #
      # @param [String] id The unique ID of the User.
      #
      # @return WorkOS::User
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
      def list_users(options = {})
        options[:order] ||= 'desc'
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
      # @param [String] external_id The user's external ID.
      # @param [String] password_hash The user's hashed password.
      # @option [String] password_hash_type The algorithm originally used to hash the password.
      #
      # @return [WorkOS::User]
      # rubocop:disable Metrics/ParameterLists
      def create_user(
        email:,
        password: nil,
        first_name: nil,
        last_name: nil,
        email_verified: nil,
        external_id: nil,
        password_hash: nil,
        password_hash_type: nil
      )
        request = post_request(
          path: '/user_management/users',
          body: {
            email: email,
            password: password,
            first_name: first_name,
            last_name: last_name,
            email_verified: email_verified,
            external_id: external_id,
            password_hash: password_hash,
            password_hash_type: password_hash_type,
          }.compact,
          auth: true,
        )

        response = execute_request(request: request)

        WorkOS::User.new(response.body)
      end

      # Update a user
      #
      # @param [String] id of the user.
      # @param [String] email of the user.
      # @param [String] first_name The user's first name.
      # @param [String] last_name The user's last name.
      # @param [Boolean] email_verified Whether the user's email address was previously verified.
      # @param [String] external_id The users's external ID
      # @param [String] password The user's password.
      # @param [String] password_hash The user's hashed password.
      # @option [String] password_hash_type The algorithm originally used to hash the password.
      #  Valid values are bcrypt.
      #
      # @return [WorkOS::User]
      def update_user(
        id:,
        email: :not_set,
        first_name: :not_set,
        last_name: :not_set,
        email_verified: :not_set,
        external_id: :not_set,
        password: :not_set,
        password_hash: :not_set,
        password_hash_type: :not_set
      )
        request = put_request(
          path: "/user_management/users/#{id}",
          body: {
            email: email,
            first_name: first_name,
            last_name: last_name,
            email_verified: email_verified,
            external_id: external_id,
            password: password,
            password_hash: password_hash,
            password_hash_type: password_hash_type,
          }.reject { |_, v| v == :not_set },
          auth: true,
        )

        response = execute_request(request: request)

        WorkOS::User.new(response.body)
      end
      # rubocop:enable Metrics/ParameterLists

      # Delete a User
      #
      # @param [String] id The unique ID of the User.
      #
      # @return [Bool] - returns `true` if successful
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
      # @param [Hash] session An optional hash that determines whether the session should be sealed and
      # the optional cookie password.
      #
      # @return WorkOS::AuthenticationResponse
      def authenticate_with_password(
        email:,
        password:,
        client_id:,
        ip_address: nil,
        user_agent: nil,
        session: nil
      )
        validate_session(session)

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

        WorkOS::AuthenticationResponse.new(response.body, session)
      end

      # Authenticate a user using OAuth or an organization's SSO connection.
      #
      # @param [String] code The authorization value which was passed back as a
      # query parameter in the callback to the Redirect URI.
      # @param [String] client_id The WorkOS client ID for the environment
      # @param [String] ip_address The IP address of the request from the user who is attempting to authenticate.
      # @param [String] user_agent The user agent of the request from the user who is attempting to authenticate.
      # @param [Hash] session An optional hash that determines whether the session should be sealed and
      # the optional cookie password.
      #
      # @return WorkOS::AuthenticationResponse
      def authenticate_with_code(
        code:,
        client_id:,
        ip_address: nil,
        user_agent: nil,
        session: nil
      )
        validate_session(session)

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

        WorkOS::AuthenticationResponse.new(response.body, session)
      end

      # Authenticate a user using a refresh token.
      #
      # @param [String] refresh_token The refresh token previously obtained from a successful authentication call
      # @param [String] client_id The WorkOS client ID for the environment
      # @param [String] organization_id The organization to issue the new access token for. (Optional)
      # @param [String] ip_address The IP address of the request from the user who is attempting to authenticate.
      # @param [String] user_agent The user agent of the request from the user who is attempting to authenticate.
      # @param [Hash] session An optional hash that determines whether the session should be sealed and
      # the optional cookie password.
      #
      # @return WorkOS::RefreshAuthenticationResponse
      def authenticate_with_refresh_token(
        refresh_token:,
        client_id:,
        organization_id: nil,
        ip_address: nil,
        user_agent: nil,
        session: nil
      )
        validate_session(session)

        response = execute_request(
          request: post_request(
            path: '/user_management/authenticate',
            body: {
              refresh_token: refresh_token,
              client_id: client_id,
              client_secret: WorkOS.config.key!,
              ip_address: ip_address,
              user_agent: user_agent,
              grant_type: 'refresh_token',
              organization_id: organization_id,
            },
          ),
        )

        WorkOS::RefreshAuthenticationResponse.new(response.body, session)
      end

      # Authenticate user by Magic Auth Code.
      #
      # @param [String] code The one-time code that was emailed to the user.
      # @param [String] email The email address of the user.
      # @param [String] client_id The WorkOS client ID for the environment.
      # @param [String] ip_address The IP address of the request from the user who is attempting to authenticate.
      # @param [String] link_authorization_code Used to link an OAuth profile to an existing user,
      # after having completed a Magic Code challenge.
      # @param [String] user_agent The user agent of the request from the user who is attempting to authenticate.
      # @param [Hash] session An optional hash that determines whether the session should be sealed and
      # the optional cookie password.
      #
      # @return WorkOS::AuthenticationResponse
      # rubocop:disable Metrics/ParameterLists
      def authenticate_with_magic_auth(
        code:,
        email:,
        client_id:,
        ip_address: nil,
        user_agent: nil,
        link_authorization_code: nil,
        session: nil
      )
        validate_session(session)

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

        WorkOS::AuthenticationResponse.new(response.body, session)
      end
      # rubocop:enable Metrics/ParameterLists

      # Authenticate a user into an organization they are a member of.
      #
      # @param [String] client_id The WorkOS client ID for the environment.
      # @param [String] organization_id The organization ID the user selected to sign in to.
      # @param [String] pending_authentication_token The pending authentication token
      # @param [String] ip_address The IP address of the request from the user who is attempting to authenticate.
      # @param [String] user_agent The user agent of the request from the user who is attempting to authenticate.
      # @param [Hash] session An optional hash that determines whether the session should be sealed and
      # the optional cookie password.
      #
      # @return WorkOS::AuthenticationResponse
      def authenticate_with_organization_selection(
        client_id:,
        organization_id:,
        pending_authentication_token:,
        ip_address: nil,
        user_agent: nil,
        session: nil
      )
        validate_session(session)

        response = execute_request(
          request: post_request(
            path: '/user_management/authenticate',
            body: {
              client_id: client_id,
              client_secret: WorkOS.config.key!,
              ip_address: ip_address,
              user_agent: user_agent,
              grant_type: 'urn:workos:oauth:grant-type:organization-selection',
              organization_id: organization_id,
              pending_authentication_token: pending_authentication_token,
            },
          ),
        )

        WorkOS::AuthenticationResponse.new(response.body, session)
      end

      # Authenticate a user using TOTP.
      #
      # @param [String] code The one-time code that was emailed to the user.
      # @param [String] client_id The WorkOS client ID for the environment
      # @param [String] pending_authentication_token The pending authentication token
      # from the initial authentication request.
      # @param [String] authentication_challenge_id The authentication challenge ID for the
      # authentication request.
      # @param [String] ip_address The IP address of the request from the user who is attempting to authenticate.
      # @param [String] user_agent The user agent of the request from the user who is attempting to authenticate.
      # @param [Hash] session An optional hash that determines whether the session should be sealed and
      # the optional cookie password.
      #
      # @return WorkOS::AuthenticationResponse
      # rubocop:disable Metrics/ParameterLists
      def authenticate_with_totp(
        code:,
        client_id:,
        pending_authentication_token:,
        authentication_challenge_id:,
        ip_address: nil,
        user_agent: nil,
        session: nil
      )
        validate_session(session)

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

        WorkOS::AuthenticationResponse.new(response.body, session)
      end
      # rubocop:enable Metrics/ParameterLists

      # Authenticate a user using Email Verification Code.
      #
      # @param [String] code The one-time code that was emailed to the user.
      # @param [String] client_id The WorkOS client ID for the environment
      # @param [String] pending_authentication_token The token returned from a failed email/password or OAuth
      # authentication attempt due to an unverified email address.
      # @param [String] ip_address The IP address of the request from the user who is attempting to authenticate.
      # @param [String] user_agent The user agent of the request from the user who is attempting to authenticate.
      # @param [Hash] session An optional hash that determines whether the session should be sealed and
      # the optional cookie password.
      #
      # @return WorkOS::AuthenticationResponse
      def authenticate_with_email_verification(
        code:,
        client_id:,
        pending_authentication_token:,
        ip_address: nil,
        user_agent: nil,
        session: nil
      )
        validate_session(session)

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

        WorkOS::AuthenticationResponse.new(response.body, session)
      end

      # Get the logout URL for a session
      #
      # The user's browser should be navigated to this URL
      #
      # @param [String] session_id The session ID can be found in the `sid`
      #   claim of the access token
      # @param [String] return_to The URL to redirect the user to after logging out
      #
      # @return String
      def get_logout_url(session_id:, return_to: nil)
        params = { session_id: session_id }
        params[:return_to] = return_to if return_to

        URI::HTTPS.build(
          host: WorkOS.config.api_hostname,
          path: '/user_management/sessions/logout',
          query: URI.encode_www_form(params),
        ).to_s
      end

      # Revokes a session
      #
      # @param [String] session_id The session ID can be found in the `sid`
      #   claim of the access token
      def revoke_session(session_id:)
        response = execute_request(
          request: post_request(
            path: '/user_management/sessions/revoke',
            body: {
              session_id: session_id,
            },
            auth: true,
          ),
        )

        response.is_a? Net::HTTPSuccess
      end

      # Get the JWKS URL
      #
      # The JWKS can be used to validate the access token returned upon successful authentication
      #
      # @param [String] client_id The WorkOS client ID for the environment
      #
      # @return String
      def get_jwks_url(client_id)
        URI::HTTPS.build(
          host: WorkOS.config.api_hostname,
          path: "/sso/jwks/#{client_id}",
        ).to_s
      end

      # Gets a Magic Auth object
      #
      # @param [String] id The unique ID of the MagicAuth object.
      #
      # @return WorkOS::MagicAuth
      def get_magic_auth(id:)
        response = execute_request(
          request: get_request(
            path: "/user_management/magic_auth/#{id}",
            auth: true,
          ),
        )

        WorkOS::MagicAuth.new(response.body)
      end

      # Creates a MagicAuth code
      #
      # @param [String] email The email address of the recipient.
      # @param [String] invitation_token The token of an Invitation, if required.
      #
      # @return WorkOS::MagicAuth
      def create_magic_auth(email:, invitation_token: nil)
        response = execute_request(
          request: post_request(
            path: '/user_management/magic_auth',
            body: {
              email: email,
              invitation_token: invitation_token,
            }.compact,
            auth: true,
          ),
        )

        WorkOS::MagicAuth.new(response.body)
      end

      # Create a one-time Magic Auth code and emails it to the user.
      #
      # @param [String] email The email address the one-time code will be sent to.
      #
      # @return Boolean
      def send_magic_auth_code(email:)
        warn_deprecation '`send_magic_auth_code` is deprecated.
        Please use `create_magic_auth` instead. This method will be removed in a future major version.'

        response = execute_request(
          request: post_request(
            path: '/user_management/magic_auth/send',
            body: {
              email: email,
            },
            auth: true,
          ),
        )

        response.is_a? Net::HTTPSuccess
      end

      # Enroll a user into an authentication factor.
      #
      # @param [String] user_id The id for the user.
      # @param [String] type The type of the factor to enroll. Only option available is totp.
      # @param [String] totp_issuer For totp factors. Typically your application
      #  or company name, this helps users distinguish between factors in authenticator apps.
      # @param [String] totp_user For totp factors. Used as the account name in authenticator apps.
      # @param [String] totp_secret For totp factors.  The Base32 encdoded secret key for the
      # factor. Generated if not provided. (Optional)
      #
      # @return WorkOS::AuthenticationFactorAndChallenge
      def enroll_auth_factor(user_id:, type:, totp_issuer: nil, totp_user: nil, totp_secret: nil)
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
              totp_secret: totp_secret,
            }.compact,
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

      # Gets an email verification object
      #
      # @param [String] id The unique ID of the EmailVerification object.
      #
      # @return WorkOS::EmailVerification
      def get_email_verification(id:)
        response = execute_request(
          request: get_request(
            path: "/user_management/email_verification/#{id}",
            auth: true,
          ),
        )

        WorkOS::EmailVerification.new(response.body)
      end

      # Sends a verification email to the provided user.
      #
      # @param [String] user_id The unique ID of the User whose email address will be verified.
      #
      # @return WorkOS::UserResponse
      def send_verification_email(user_id:)
        response = execute_request(
          request: post_request(
            path: "/user_management/users/#{user_id}/email_verification/send",
            auth: true,
          ),
        )

        WorkOS::UserResponse.new(response.body)
      end

      # Verifiy user email using one-time code that was sent to the user.
      #
      # @param [String] user_id The unique ID of the User whose email address will be verified.
      # @param [String] code The one-time code emailed to the user.
      #
      # @return WorkOS::UserResponse
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

      # Gets a password reset object
      #
      # @param [String] id The unique ID of the PasswordReset object.
      #
      # @return WorkOS::PasswordReset
      def get_password_reset(id:)
        response = execute_request(
          request: get_request(
            path: "/user_management/password_reset/#{id}",
            auth: true,
          ),
        )

        WorkOS::PasswordReset.new(response.body)
      end

      # Creates a password reset token
      #
      # @param [String] email The email address of the user.
      #
      # @return WorkOS::PasswordReset
      def create_password_reset(email:)
        response = execute_request(
          request: post_request(
            path: '/user_management/password_reset',
            body: {
              email: email,
            },
            auth: true,
          ),
        )

        WorkOS::PasswordReset.new(response.body)
      end

      # Create a password reset challenge and emails a password reset link to a user.
      #
      # @param [String] email The email of the user that wishes to reset their password.
      # @param [String] password_reset_url The URL that will be linked to in the email.
      #
      # @return [Bool] - returns `true` if successful
      def send_password_reset_email(email:, password_reset_url:)
        warn_deprecation '`send_password_reset_email` is deprecated.
        Please use `create_password_reset` instead. This method will be removed in a future major version.'

        request = post_request(
          path: '/user_management/password_reset/send',
          body: {
            email: email,
            password_reset_url: password_reset_url,
          },
          auth: true,
        )

        response = execute_request(request: request)

        response.is_a? Net::HTTPSuccess
      end

      # Reset user password using token that was sent to the user.
      #
      # @param [String] token The token that was sent to the user.
      # @param [String] new_password The new password to set for the user.
      #
      # @return WorkOS::User
      def reset_password(token:, new_password:)
        response = execute_request(
          request: post_request(
            path: '/user_management/password_reset/confirm',
            body: {
              token: token,
              new_password: new_password,
            },
            auth: true,
          ),
        )

        WorkOS::User.new(response.body)
      end

      # Get an Organization Membership
      #
      # @param [String] id The unique ID of the Organization Membership.
      #
      # @return WorkOS::OrganizationMembership
      def get_organization_membership(id:)
        response = execute_request(
          request: get_request(
            path: "/user_management/organization_memberships/#{id}",
            auth: true,
          ),
        )

        WorkOS::OrganizationMembership.new(response.body)
      end

      # Retrieve a list of Organization Memberships.
      #
      # @param [Hash] options
      # @option options [String] user_id The ID of the User.
      # @option options [String] organization_id Filter memberships by the organization they are members of.
      # @option options [Array<String>] statuses Filter memberships by status.
      # @option options [String] limit Maximum number of records to return.
      # @option options [String] order The order in which to paginate records
      # @option options [String] before Pagination cursor to receive records
      #  before a provided User ID.
      # @option options [String] after Pagination cursor to receive records
      #  before a provided User ID.
      #
      # @return [WorkOS::OrganizationMembership]
      def list_organization_memberships(options = {})
        options[:order] ||= 'desc'
        response = execute_request(
          request: get_request(
            path: '/user_management/organization_memberships',
            auth: true,
            params: options,
          ),
        )

        parsed_response = JSON.parse(response.body)

        organization_memberships = parsed_response['data'].map do |organization_membership|
          ::WorkOS::OrganizationMembership.new(organization_membership.to_json)
        end

        WorkOS::Types::ListStruct.new(
          data: organization_memberships,
          list_metadata: parsed_response['list_metadata'],
        )
      end

      # Create an Organization Membership
      #
      # @param [String] user_id The ID of the User.
      # @param [String] organization_id The ID of the Organization to which the user belongs to.
      # @param [String] role_slug The slug of the role to grant to this membership. (Optional)
      #
      # @return [WorkOS::OrganizationMembership]
      def create_organization_membership(user_id:, organization_id:, role_slug: nil)
        request = post_request(
          path: '/user_management/organization_memberships',
          body: {
            user_id: user_id,
            organization_id: organization_id,
            role_slug: role_slug,
          }.compact,
          auth: true,
        )

        response = execute_request(request: request)

        WorkOS::OrganizationMembership.new(response.body)
      end

      # Update an Organization Membership
      #
      # @param [String] organization_membership_id The ID of the Organization Membership.
      # @param [String] role_slug The slug of the role to grant to this membership.
      #
      # @return [WorkOS::OrganizationMembership]
      def update_organization_membership(id:, role_slug:)
        request = put_request(
          path: "/user_management/organization_memberships/#{id}",
          body: {
            id: id,
            role_slug: role_slug,
          },
          auth: true,
        )

        response = execute_request(request: request)

        WorkOS::OrganizationMembership.new(response.body)
      end

      # Delete an Organization Membership
      #
      # @param [String] id The unique ID of the Organization Membership.
      #
      # @return [Bool] - returns `true` if successful
      def delete_organization_membership(id:)
        response = execute_request(
          request: delete_request(
            path: "/user_management/organization_memberships/#{id}",
            auth: true,
          ),
        )

        response.is_a? Net::HTTPSuccess
      end

      # Deactivate an Organization Membership
      #
      # @param [String] id The unique ID of the Organization Membership.
      #
      # @return WorkOS::OrganizationMembership
      def deactivate_organization_membership(id:)
        response = execute_request(
          request: put_request(
            path: "/user_management/organization_memberships/#{id}/deactivate",
            auth: true,
          ),
        )

        WorkOS::OrganizationMembership.new(response.body)
      end

      # Reactivate an Organization Membership
      #
      # @param [String] id The unique ID of the Organization Membership.
      #
      # @return WorkOS::OrganizationMembership
      def reactivate_organization_membership(id:)
        response = execute_request(
          request: put_request(
            path: "/user_management/organization_memberships/#{id}/reactivate",
            auth: true,
          ),
        )

        WorkOS::OrganizationMembership.new(response.body)
      end

      # Gets an Invitation
      #
      # @param [String] id The unique ID of the Invitation.
      #
      # @return WorkOS::Invitation
      def get_invitation(id:)
        response = execute_request(
          request: get_request(
            path: "/user_management/invitations/#{id}",
            auth: true,
          ),
        )

        WorkOS::Invitation.new(response.body)
      end

      # Finds an Invitation by Token
      #
      # @param [String] token The token of the Invitation.
      #
      # @return WorkOS::Invitation
      def find_invitation_by_token(token:)
        response = execute_request(
          request: get_request(
            path: "/user_management/invitations/by_token/#{token}",
            auth: true,
          ),
        )

        WorkOS::Invitation.new(response.body)
      end

      # Retrieve a list of invitations.
      #
      # @param [Hash] options
      # @option options [String] email The email address of a recipient.
      # @option options [String] organization_id The ID of the Organization that the recipient was invited to join.
      # @option options [String] limit Maximum number of records to return.
      # @option options [String] order The order in which to paginate records
      # @option options [String] before Pagination cursor to receive records
      #  before a provided User ID.
      # @option options [String] after Pagination cursor to receive records
      #  before a provided User ID.
      #
      # @return [WorkOS::Invitation]
      def list_invitations(options = {})
        options[:order] ||= 'desc'
        response = execute_request(
          request: get_request(
            path: '/user_management/invitations',
            auth: true,
            params: options,
          ),
        )

        parsed_response = JSON.parse(response.body)

        invitations = parsed_response['data'].map do |invitation|
          ::WorkOS::Invitation.new(invitation.to_json)
        end

        WorkOS::Types::ListStruct.new(
          data: invitations,
          list_metadata: parsed_response['list_metadata'],
        )
      end

      # Sends an Invitation to a recipient.
      #
      # @param [String] email The email address of the recipient.
      # @param [String] organization_id The ID of the Organization to which the recipient is being invited.
      # @param [Integer] expires_in_days The number of days the invitations will be valid for.
      # Must be between 1 and 30, defaults to 7 if not specified.
      # @param [String] inviter_user_id The ID of the User sending the invitation.
      # @param [String] role_slug The slug of the role to assign to the user upon invitation.
      #
      # @return WorkOS::Invitation
      def send_invitation(email:, organization_id: nil, expires_in_days: nil, inviter_user_id: nil, role_slug: nil)
        response = execute_request(
          request: post_request(
            path: '/user_management/invitations',
            body: {
              email: email,
              organization_id: organization_id,
              expires_in_days: expires_in_days,
              inviter_user_id: inviter_user_id,
              role_slug: role_slug,
            }.compact,
            auth: true,
          ),
        )

        WorkOS::Invitation.new(response.body)
      end

      # Revokes an existing Invitation.
      #
      # @param [String] id The unique ID of the Invitation.
      #
      # @return WorkOS::Invitation
      def revoke_invitation(id:)
        request = post_request(
          path: "/user_management/invitations/#{id}/revoke",
          auth: true,
        )

        response = execute_request(request: request)

        WorkOS::Invitation.new(response.body)
      end

      private

      def validate_session(session)
        return unless session && (session[:seal_session] == true) && session[:cookie_password].nil?

        raise ArgumentError, 'cookie_password is required when sealing session'
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
