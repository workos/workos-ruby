# frozen_string_literal: true

module WorkOS
  # The OAuthTokens class represents the third party providerOAuth tokens returned in the authentication response.
  # This class is not meant to be instantiated in user space, and is instantiated internally but exposed.
  class OAuthTokens
    include HashProvider

    attr_accessor :access_token, :refresh_token, :scopes, :expires_at

    def initialize(json)
      hash = JSON.parse(json, symbolize_names: true)

      @access_token = hash[:access_token]
      @refresh_token = hash[:refresh_token]
      @scopes = hash[:scopes]
      @expires_at = hash[:expires_at]
    end

    def to_json(*)
      {
        access_token: access_token,
        refresh_token: refresh_token,
        scopes: scopes,
        expires_at: expires_at,
      }
    end
  end
end 