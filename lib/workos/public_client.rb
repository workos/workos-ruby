# frozen_string_literal: true

# @oagen-ignore-file
# Hand-maintained public-client factory (H19).
# Public clients (browser, mobile, CLI, desktop) cannot store an API key
# securely; they use PKCE flows and operate without an api_key.

module WorkOS
  module PublicClient
    module_function

    # Construct a WorkOS::Client suitable for PKCE-only / public-client use.
    # No api_key is required — methods that would normally send a Bearer
    # Authorization header will skip it. Use PKCE flows on user_management
    # and sso (`get_authorization_url_with_pkce`, `authenticate_with_code_pkce`,
    # etc.) instead of methods that require server-side credentials.
    #
    # @param client_id [String] WorkOS client ID for the application.
    # @param base_url [String] Optional override of the API base URL.
    # @param timeout [Integer] HTTP timeout in seconds.
    # @return [WorkOS::Client]
    def create(client_id:, base_url: nil, timeout: nil)
      raise ArgumentError, "client_id is required" if client_id.nil? || client_id.empty?
      args = {client_id: client_id}
      args[:base_url] = base_url if base_url
      args[:timeout] = timeout if timeout
      WorkOS::Client.new(**args)
    end
  end
end
