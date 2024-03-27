# frozen_string_literal: true

module WorkOS
  # The RefreshAuthenticationResponse contains response data from a successful
  # `UserManagement.authenticate_with_refresh_token` call
  class RefreshAuthenticationResponse
    include HashProvider

    attr_accessor :access_token, :refresh_token

    def initialize(authentication_response_json)
      json = JSON.parse(authentication_response_json, symbolize_names: true)
      @access_token = json[:access_token]
      @refresh_token = json[:refresh_token]
    end

    def to_json(*)
      {
        access_token: access_token,
        refresh_token: refresh_token,
      }
    end
  end
end
