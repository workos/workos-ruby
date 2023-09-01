# frozen_string_literal: true
# typed: true

require 'net/http'
require 'uri'

module WorkOS
  # The UserManagement module provides convenience methods for working with the
  # WorkOS User platform. You'll need a valid API key.

  # rubocop:disable Metrics/ModuleLength
  module UserManagement
    class << self
      extend T::Sig
      include Client

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
      def confirm_password_reset(token:, new_password:)
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
      def create_password_reset_challenge(email:, password_reset_url:)
        request = post_request(
          path: '/users/password_reset_challenge',
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

      # Enroll a user into an authentication factor.
      #
      # @param [String] id The id for the user.
      #
      # @return WorkOS::AuthenticationFactorAndChallenge
      sig do
        params(
          id: String,
        ).returns(WorkOS::AuthenticationFactorAndChallenge)
      end
      def enroll_auth_factor(id:)
        response = execute_request(
          request: post_request(
            path: "/users/#{id}/auth/factors",
            body: {
              type: 'topd',
            },
            auth: true,
          ),
        )

        WorkOS::AuthenticationFactorAndChallenge.new(response.body)
      end

      # Get all auth factors for a user
      #
      # @param [String] id The id for the user.
      #
      # @return WorkOS::Factor
      sig do
        params(
          id: String,
        ).returns(WorkOS::Types::ListStruct)
      end
      def list_auth_factors(id:)
        response = execute_request(
          request: get_request(
            path: "/users/#{id}/auth/factors",
            auth: true,
          ),
        )

        parsed_response = JSON.parse(response.body)

        auth_factors = parsed_response.map do |auth_factor|
          ::WorkOS::Factor.new(auth_factor.to_json)
        end

        WorkOS::Types::ListStruct.new(
          data: auth_factors,
          list_metadata: {},
        )
      end
    end
  end
  # rubocop:enable Metrics/ModuleLength
end
