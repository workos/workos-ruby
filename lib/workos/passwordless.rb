# frozen_string_literal: true

require 'net/http'

module WorkOS
  # The Passwordless module provides convenience methods for working with
  # passwordless sessions including the WorkOS Magic Link. You'll need a valid
  # API key.
  #
  # @see https://workos.com/docs/sso/configuring-magic-link
  module Passwordless
    class << self
      include Client

      # Create a Passwordless Session.
      #
      # @param [Hash] options A hash with options for the session
      # @option options [String] email The email of the user to authenticate.
      # @option options [String] state Optional parameter that the redirect URI
      #  received from WorkOS will contain. The state parameter can be used to
      #  encode arbitrary information to help restore application state between
      #  redirects.
      # @option options [String] connection Optional parameter for the ID of a
      #  specific connection. This can be used to create a Passwordless Session
      #  for a specific connection rather than using the domain from the email
      #  to determine the Organization and Connection.
      # @option options [String] type The type of Passwordless Session to
      #  create. Currently, the only supported value is 'MagicLink'.
      # @option options [String] redirect_uri The URI where users are directed
      #  after completing the authentication step. Must match a
      #  configured redirect URI on your WorkOS dashboard.
      #
      # @return Hash
      def create_session(options)
        response = execute_request(
          request: post_request(
            path: '/passwordless/sessions',
            auth: true,
            body: options,
          ),
        )

        hash = JSON.parse(response.body)

        WorkOS::Types::PasswordlessSessionStruct.new(
          id: hash['id'],
          email: hash['email'],
          expires_at: Date.parse(hash['expires_at']),
          link: hash['link'],
        )
      end

      # Send a Passwordless Session via email.
      #
      # @param [String] session_id The unique identifier of the Passwordless
      #  Session to send an email for.
      #
      # @return Hash
      def send_session(session_id)
        response = execute_request(
          request: post_request(
            path: "/passwordless/sessions/#{session_id}/send",
            auth: true,
          ),
        )

        JSON.parse(response.body)
      end
    end
  end
end
