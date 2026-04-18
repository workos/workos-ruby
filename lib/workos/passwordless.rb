# frozen_string_literal: true

# @oagen-ignore-file
# Hand-maintained: Passwordless session endpoints are not yet in the OpenAPI
# spec, so this module wraps them until they are.
# See https://workos.com/docs/reference/magic-link.
require "json"

module WorkOS
  # Passwordless authentication sessions (magic-link).
  #
  #   session = client.passwordless.create_session(email: "user@example.com")
  #   client.passwordless.send_session(session.id)
  class Passwordless
    PasswordlessSession = Struct.new(:id, :email, :expires_at, :link, :object, keyword_init: true) do
      def self.from_hash(hash)
        new(
          id: hash["id"],
          email: hash["email"],
          expires_at: hash["expires_at"],
          link: hash["link"],
          object: hash["object"] || "passwordless_session"
        )
      end

      def to_h
        super.compact
      end
    end

    def initialize(client)
      @client = client
    end

    # Create a passwordless session.
    #
    # @param email [String] Email of the user to authenticate.
    # @param type [String] Session type. Currently only "MagicLink" is supported.
    # @param redirect_uri [String, nil] Where to redirect the user after auth.
    # @param state [String, nil] Arbitrary state echoed back on redirect.
    # @param connection [String, nil] Specific connection ID to use.
    # @param expires_in [Integer, nil] Lifetime in seconds.
    # @param request_options [Hash] Per-request overrides.
    # @return [PasswordlessSession]
    def create_session(email:, type: "MagicLink", redirect_uri: nil, state: nil, connection: nil, expires_in: nil, request_options: {})
      body = {
        "email" => email,
        "type" => type,
        "redirect_uri" => redirect_uri,
        "state" => state,
        "connection" => connection,
        "expires_in" => expires_in
      }.compact
      response = @client.request(method: :post, path: "/passwordless/sessions", auth: true, body: body, request_options: request_options)
      PasswordlessSession.from_hash(JSON.parse(response.body))
    end

    # Send the magic-link email for an existing passwordless session.
    #
    # @param session_id [String] Unique identifier of the passwordless session.
    # @param request_options [Hash] Per-request overrides.
    # @return [Hash] Server response payload.
    def send_session(session_id, request_options: {})
      response = @client.request(
        method: :post,
        path: "/passwordless/sessions/#{WorkOS::Util.encode_path(session_id)}/send",
        auth: true,
        body: {},
        request_options: request_options
      )
      JSON.parse(response.body || "{}")
    rescue JSON::ParserError
      {}
    end
  end
end
