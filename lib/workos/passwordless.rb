# frozen_string_literal: true
# typed: true

require 'net/http'
require 'uri'

module WorkOS
  # The Passwordless module provides convenience methods for working with
  # passwordless sessions including the WorkOS Magic Link. You'll need a valid API key.
  #
  # @see https://workos.com/docs/sso/configuring-magic-link
  module Passwordless
    class << self
      extend T::Sig
      include Base
      include Client

      # Create an Passwordless Session.
      #
      # @param [Hash] options A hash with options for the session
      # @option options [String] email The email of the user to authenticate.
      # @option options [String] state Optional parameter that the redirect URI
      #  received from WorkOS will contain. The state parameter can be used to
      #  encode arbitrary information to help restore application state between
      #  redirects.
      # @option options [String] type The type of Passwordless Session to create.
      #  Currently, the only supported value is 'MagicLink'.
      #
      # @return Hash
      sig do
        params(
          options: Hash,
        ).returns(::T.untyped)
      end

      def create_session(options)
        request = post_request(
          path: '/passwordless/sessions',
          auth: true,
          body: options,
        )

        execute_request(request: request)
      end

      # Send a Passwordless Session via email.
      #
      # @param [String] session_id The unique identifier of the Passwordless
      #  Session to send an email for.
      #
      # @return Hash
      sig do
        params(
          session_id: String
        ).returns(T::Hash[String, T::Boolean])
      end

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
