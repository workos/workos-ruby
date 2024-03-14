# frozen_string_literal: true
# typed: true

module WorkOS
  # The AuthenticationResponse class represents an Authentication Response as well as an corresponding
  # response data that can later be appended on.
  class AuthenticationResponse
    include HashProvider
    extend T::Sig

    attr_accessor :user, :organization_id, :impersonator

    sig { params(authentication_response_json: String).void }
    def initialize(authentication_response_json)
      json = JSON.parse(authentication_response_json, symbolize_names: true)
      @user = WorkOS::User.new(json[:user].to_json)
      @organization_id = T.let(json[:organization_id], T.nilable(String))
      @impersonator =
        if (impersonator_json = json[:impersonator])
          Impersonator.new(email: impersonator_json[:email],
                           reason: impersonator_json[:reason],)
        end
    end

    def to_json(*)
      {
        user: user.to_json,
        organization_id: organization_id,
        impersonator: impersonator.to_json,
      }
    end
  end
end
