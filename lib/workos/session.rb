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
    attr_accessor :jwks, :jwks_algorithms, :user_management, :cookie_password, :session_data, :client_id

    def initialize(user_management:, client_id:, session_data:, cookie_password:)
      raise ArgumentError, 'cookiePassword is required' if cookie_password.nil? || cookie_password.empty?

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
    # @return [Hash] A hash containing the authentication response and a reason if the authentication failed
    # rubocop:disable Metrics/AbcSize
    def authenticate
      return { authenticated: false, reason: 'NO_SESSION_COOKIE_PROVIDED' } if @session_data.nil?

      begin
        session = Session.unseal_data(@session_data, @cookie_password)
      rescue StandardError
        return { authenticated: false, reason: 'INVALID_SESSION_COOKIE' }
      end

      return { authenticated: false, reason: 'INVALID_SESSION_COOKIE' } unless session[:access_token]
      return { authenticated: false, reason: 'INVALID_JWT' } unless is_valid_jwt(session[:access_token])

      decoded = JWT.decode(session[:access_token], nil, true, algorithms: @jwks_algorithms, jwks: @jwks).first

      {
        authenticated: true,
        session_id: decoded['sid'],
        organization_id: decoded['org_id'],
        role: decoded['role'],
        roles: decoded['roles'] || [],
        permissions: decoded['permissions'],
        entitlements: decoded['entitlements'],
        feature_flags: decoded['feature_flags'],
        user: session[:user],
        impersonator: session[:impersonator],
        reason: nil,
      }
    end

    # Refreshes the session data using the refresh token stored in the session data
    # @param options [Hash] Options for refreshing the session
    # @option options [String] :cookie_password The password to use for unsealing the session data
    # @option options [String] :organization_id The organization ID to use for refreshing the session
    # @return [Hash] A hash containing a new sealed session, the authentication response,
    # and a reason if the refresh failed
    # rubocop:disable Metrics/PerceivedComplexity
    def refresh(options = nil)
      cookie_password = options.nil? || options[:cookie_password].nil? ? @cookie_password : options[:cookie_password]

      begin
        session = Session.unseal_data(@session_data, cookie_password)
      rescue StandardError
        return { authenticated: false, reason: 'INVALID_SESSION_COOKIE' }
      end

      return { authenticated: false, reason: 'INVALID_SESSION_COOKIE' } unless session[:refresh_token] && session[:user]

      begin
        auth_response = @user_management.authenticate_with_refresh_token(
          client_id: @client_id,
          refresh_token: session[:refresh_token],
          organization_id: options.nil? || options[:organization_id].nil? ? nil : options[:organization_id],
          session: { seal_session: true, cookie_password: cookie_password },
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

    # Encrypts and seals data using AES-256-GCM
    # @param data [Hash] The data to seal
    # @param key [String] The key to use for encryption
    # @return [String] The sealed data
    def self.seal_data(data, key)
      iv = SecureRandom.random_bytes(12)

      encrypted_data = Encryptor.encrypt(
        value: JSON.generate(data),
        key: key,
        iv: iv,
        algorithm: 'aes-256-gcm',
      )
      Base64.encode64(iv + encrypted_data) # Combine IV with encrypted data and encode as base64
    end

    # Decrypts and unseals data using AES-256-GCM
    # @param sealed_data [String] The sealed data to unseal
    # @param key [String] The key to use for decryption
    # @return [Hash] The unsealed data
    def self.unseal_data(sealed_data, key)
      decoded_data = Base64.decode64(sealed_data)
      iv = decoded_data[0..11] # Extract the IV (first 12 bytes)
      encrypted_data = decoded_data[12..-1] # Extract the encrypted data

      decrypted_data = Encryptor.decrypt(
        value: encrypted_data,
        key: key,
        iv: iv,
        algorithm: 'aes-256-gcm',
      )

      JSON.parse(decrypted_data, symbolize_names: true) # Parse the decrypted JSON string back to original data
    end

    private

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

    # Validates a JWT token using the JWKS set
    # @param token [String] The JWT token to validate
    # @return [Boolean] True if the token is valid, false otherwise
    # rubocop:disable Naming/PredicateName
    def is_valid_jwt(token)
      JWT.decode(token, nil, true, algorithms: @jwks_algorithms, jwks: @jwks)
      true
    rescue StandardError
      false
    end
    # rubocop:enable Naming/PredicateName
  end
end
