# frozen_string_literal: true

require 'jwt'
require 'uri'
require 'net/http'
require 'encryptor'
require 'securerandom'
require 'json'
require 'uri'

module WorkOS
  # The Session class provides helper methods for working with WorkOS sessions
  # This class is not meant to be instantiated in a user space, and is instantiated internally but exposed.
  class Session
    attr_accessor :jwks, :jwks_algorithms, :user_management, :cookie_password, :session_data, :client_id, :encryptor

    def initialize(user_management:, client_id:, session_data:, cookie_password:, encryptor: nil)
      raise ArgumentError, 'cookiePassword is required' if cookie_password.nil? || cookie_password.empty?

      @encryptor = encryptor || WorkOS::Encryptors::AesGcm.new
      validate_encryptor!(@encryptor)

      @user_management = user_management
      @cookie_password = cookie_password
      @session_data = session_data
      @client_id = client_id

      @jwks = Cache.fetch("jwks_#{client_id}", expires_in: 5 * 60) do
        create_remote_jwk_set(URI(@user_management.get_jwks_url(client_id)))
      end
      @jwks_algorithms = @jwks.map { |key| key[:alg] }.compact.uniq
    end

    # Authenticates the user based on the session data
    # @param include_expired [Boolean] If true, returns decoded token data even when expired (default: false)
    # @param block [Proc] Optional block to call to extract additional claims from the decoded JWT
    # @return [Hash] A hash containing the authentication response and a reason if the authentication failed
    # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    def authenticate(include_expired: false, &claim_extractor)
      return { authenticated: false, reason: 'NO_SESSION_COOKIE_PROVIDED' } if @session_data.nil?

      begin
        session = Session.unseal_data(@session_data, @cookie_password, encryptor: @encryptor)
      rescue StandardError
        return { authenticated: false, reason: 'INVALID_SESSION_COOKIE' }
      end

      return { authenticated: false, reason: 'INVALID_SESSION_COOKIE' } unless session[:access_token]

      begin
        decoded = JWT.decode(
          session[:access_token],
          nil,
          true,
          algorithms: @jwks_algorithms,
          jwks: @jwks,
          verify_expiration: false,
        ).first

        expired = decoded['exp'] && decoded['exp'] < Time.now.to_i

        # Early return for expired tokens when not including expired data (backward compatible)
        return { authenticated: false, reason: 'INVALID_JWT' } if expired && !include_expired

        # Return full data for valid tokens or when include_expired is true
        result = {
          authenticated: !expired,
          session_id: decoded['sid'],
          organization_id: decoded['org_id'],
          role: decoded['role'],
          roles: decoded['roles'],
          permissions: decoded['permissions'],
          entitlements: decoded['entitlements'],
          feature_flags: decoded['feature_flags'],
          user: session[:user],
          impersonator: session[:impersonator],
          reason: expired ? 'INVALID_JWT' : nil,
        }
        result.merge!(claim_extractor.call(decoded)) if block_given?
        result
      rescue JWT::DecodeError
        { authenticated: false, reason: 'INVALID_JWT' }
      rescue StandardError => e
        { authenticated: false, reason: e.message }
      end
    end

    # Refreshes the session data using the refresh token stored in the session data
    # @param options [Hash] Options for refreshing the session
    # @option options [String] :cookie_password The password to use for unsealing the session data
    # @option options [String] :organization_id The organization ID to use for refreshing the session
    # @return [Hash] A hash containing a new sealed session, the authentication response,
    # and a reason if the refresh failed
    def refresh(options = nil)
      cookie_password = options.nil? || options[:cookie_password].nil? ? @cookie_password : options[:cookie_password]

      begin
        session = Session.unseal_data(@session_data, cookie_password, encryptor: @encryptor)
      rescue StandardError
        return { authenticated: false, reason: 'INVALID_SESSION_COOKIE' }
      end

      return { authenticated: false, reason: 'INVALID_SESSION_COOKIE' } unless session[:refresh_token] && session[:user]

      begin
        auth_response = @user_management.authenticate_with_refresh_token(
          client_id: @client_id,
          refresh_token: session[:refresh_token],
          organization_id: options.nil? || options[:organization_id].nil? ? nil : options[:organization_id],
          session: { seal_session: true, cookie_password: cookie_password, encryptor: @encryptor },
        )

        @session_data = auth_response.sealed_session
        @cookie_password = cookie_password

        {
          authenticated: true,
          sealed_session: auth_response.sealed_session,
          session: auth_response,
          reason: nil,
        }
      rescue StandardError => e
        { authenticated: false, reason: e.message }
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    # Returns a URL to redirect the user to for logging out
    # @param return_to [String] The URL to redirect the user to after logging out
    # @return [String] The URL to redirect the user to for logging out
    def get_logout_url(return_to: nil)
      auth_response = authenticate

      unless auth_response[:authenticated]
        raise "Failed to extract session ID for logout URL: #{auth_response[:reason]}"
      end

      @user_management.get_logout_url(session_id: auth_response[:session_id], return_to: return_to)
    end

    # Encrypts and seals data using the provided encryptor (defaults to AES-256-GCM)
    # @param data [Hash] The data to seal
    # @param key [String] The key to use for encryption
    # @param encryptor [Object] Optional encryptor that responds to #seal(data, key)
    # @return [String] The sealed data
    def self.seal_data(data, key, encryptor: nil)
      enc = encryptor || WorkOS::Encryptors::AesGcm.new
      enc.seal(data, key)
    end

    # Decrypts and unseals data using the provided encryptor (defaults to AES-256-GCM)
    # @param sealed_data [String] The sealed data to unseal
    # @param key [String] The key to use for decryption
    # @param encryptor [Object] Optional encryptor that responds to #unseal(sealed_data, key)
    # @return [Hash] The unsealed data
    def self.unseal_data(sealed_data, key, encryptor: nil)
      enc = encryptor || WorkOS::Encryptors::AesGcm.new
      enc.unseal(sealed_data, key)
    end

    private

    def validate_encryptor!(enc)
      return if enc.respond_to?(:seal) && enc.respond_to?(:unseal)

      raise ArgumentError, 'encryptor must respond to #seal(data, key) and #unseal(sealed_data, key)'
    end

    # Creates a JWKS set from a remote JWKS URL
    # @param uri [URI] The URI of the JWKS
    # @return [JWT::JWK::Set] The JWKS set
    def create_remote_jwk_set(uri)
      # Fetch the JWKS from the remote URL
      response = Net::HTTP.get(uri)

      jwks_hash = JSON.parse(response)
      jwks = JWT::JWK::Set.new(jwks_hash)

      # filter jwks so it only returns the keys where 'use' is equal to 'sig'
      jwks.keys.select! { |key| key[:use] == 'sig' }

      jwks
    end
  end
end
