# frozen_string_literal: true

module WorkOS
  # The AuthenticationResponse class represents an Authentication Response as well as an corresponding
  # response data that can later be appended on.
  class AuthenticationResponse
    include HashProvider

    attr_accessor :user, :organization_id, :impersonator, :access_token, :refresh_token

    def initialize(authentication_response_json)
      json = JSON.parse(authentication_response_json, symbolize_names: true)
      @user = WorkOS::User.new(json[:user].to_json)
      @organization_id = json[:organization_id]
      @impersonator =
        if (impersonator_json = json[:impersonator])
          Impersonator.new(email: impersonator_json[:email],
                           reason: impersonator_json[:reason],)
        end
      @access_token = json[:access_token]
      @refresh_token = json[:refresh_token]
    end

    def to_json(*)
      {
        user: user.to_json,
        organization_id: organization_id,
        impersonator: impersonator.to_json,
        access_token: access_token,
        refresh_token: refresh_token,
      }
    end
  end
end
