# frozen_string_literal: true

module WorkOS
  # The AuthenticationResponse class represents an Authentication Response as well as an corresponding
  # response data that can later be appended on.
  class AuthenticationResponse
    include HashProvider

    attr_accessor :user,
                  :organization_id,
                  :impersonator,
                  :access_token,
                  :refresh_token,
                  :authentication_method,
                  :sealed_session,
                  :oauth_tokens

    # rubocop:disable Metrics/AbcSize
    def initialize(authentication_response_json, session = nil)
      json = JSON.parse(authentication_response_json, symbolize_names: true)
      @access_token = json[:access_token]
      @refresh_token = json[:refresh_token]
      @user = WorkOS::User.new(json[:user].to_json)
      @organization_id = json[:organization_id]
      @impersonator =
        if (impersonator_json = json[:impersonator])
          Impersonator.new(email: impersonator_json[:email],
                           reason: impersonator_json[:reason],)
        end
      @authentication_method = json[:authentication_method]
      @oauth_tokens = json[:oauth_tokens] ? WorkOS::OAuthTokens.new(json[:oauth_tokens].to_json) : nil
      @sealed_session =
        if session && session[:seal_session]
          WorkOS::Session.seal_data({
                                      access_token: access_token,
                                      refresh_token: refresh_token,
                                      user: user.to_json,
                                      organization_id: organization_id,
                                      impersonator: impersonator.to_json,
                                    }, session[:cookie_password],)
        end
    end
    # rubocop:enable Metrics/AbcSize

    def to_json(*)
      {
        user: user.to_json,
        organization_id: organization_id,
        impersonator: impersonator.to_json,
        access_token: access_token,
        refresh_token: refresh_token,
        authentication_method: authentication_method,
        sealed_session: sealed_session,
        oauth_tokens: oauth_tokens&.to_json,
      }
    end
  end
end
