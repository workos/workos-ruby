# frozen_string_literal: true

# @oagen-ignore-file
# Hand-maintained Session object (H04). Constructed by SessionManager#load.
require "json"
require "jwt"
require "openssl"
require "uri"

module WorkOS
  class Session
    def initialize(manager, seal_data:, cookie_password:)
      raise ArgumentError, "cookie_password is required" if cookie_password.nil? || cookie_password.empty?
      @manager = manager
      @client = manager.client
      @seal_data = seal_data
      @cookie_password = cookie_password
    end

    attr_reader :seal_data, :cookie_password

    def authenticate
      return SessionManager::AuthError.new(authenticated: false, reason: SessionManager::NO_SESSION_COOKIE_PROVIDED) if @seal_data.nil? || @seal_data.empty?

      session = begin
        @manager.unseal_data(@seal_data, @cookie_password)
      rescue ArgumentError, OpenSSL::Cipher::CipherError
        return SessionManager::AuthError.new(authenticated: false, reason: SessionManager::INVALID_SESSION_COOKIE)
      end
      return SessionManager::AuthError.new(authenticated: false, reason: SessionManager::INVALID_SESSION_COOKIE) unless session.is_a?(Hash) && session["access_token"]

      decoded = begin
        @manager.decode_jwt(session["access_token"])
      rescue JWT::DecodeError, JWT::ExpiredSignature
        return SessionManager::AuthError.new(authenticated: false, reason: SessionManager::INVALID_JWT)
      end

      SessionManager::AuthSuccess.new(
        authenticated: true,
        session_id: decoded["sid"],
        organization_id: decoded["org_id"],
        role: decoded["role"],
        roles: decoded["roles"],
        permissions: decoded["permissions"],
        entitlements: decoded["entitlements"],
        user: session["user"],
        impersonator: session["impersonator"],
        feature_flags: decoded["feature_flags"]
      )
    end

    def refresh(organization_id: nil, cookie_password: nil)
      effective_password = cookie_password || @cookie_password

      session = begin
        @manager.unseal_data(@seal_data, effective_password)
      rescue ArgumentError, OpenSSL::Cipher::CipherError
        return SessionManager::RefreshError.new(authenticated: false, reason: SessionManager::INVALID_SESSION_COOKIE)
      end
      return SessionManager::RefreshError.new(authenticated: false, reason: SessionManager::INVALID_SESSION_COOKIE) unless session.is_a?(Hash) && session["refresh_token"]

      body = {
        "grant_type" => "refresh_token",
        "client_id" => @client.client_id,
        "client_secret" => @client.api_key,
        "refresh_token" => session["refresh_token"],
        "session" => {"seal_session" => true, "cookie_password" => effective_password}
      }
      body["organization_id"] = organization_id if organization_id

      response = @client.execute_request(
        request: @client.post_request(path: "/user_management/authenticate", auth: false, body: body)
      )
      auth_response = JSON.parse(response.body)
      sealed = auth_response["sealed_session"].to_s
      @seal_data = sealed
      @cookie_password = effective_password

      decoded = @manager.decode_jwt(auth_response["access_token"])
      SessionManager::RefreshSuccess.new(
        authenticated: true,
        sealed_session: sealed,
        session_id: decoded["sid"],
        organization_id: decoded["org_id"],
        role: decoded["role"],
        roles: decoded["roles"],
        permissions: decoded["permissions"],
        entitlements: decoded["entitlements"],
        user: auth_response["user"],
        impersonator: auth_response["impersonator"],
        feature_flags: decoded["feature_flags"]
      )
    rescue WorkOS::Error => e
      SessionManager::RefreshError.new(authenticated: false, reason: e.message)
    end

    # Build the WorkOS session-logout URL for the currently authenticated session.
    # Requires #authenticate to succeed (so we have the session_id).
    def get_logout_url(return_to: nil)
      result = authenticate
      raise WorkOS::Error.new(message: "Failed to extract session ID for logout URL: #{result.reason}") if result.is_a?(SessionManager::AuthError)
      base = @client.base_url || "https://api.workos.com"
      params = {"session_id" => result.session_id}
      params["return_to"] = return_to if return_to
      uri = URI.join(base, "/user_management/sessions/logout")
      uri.query = URI.encode_www_form(params)
      uri.to_s
    end
  end
end
