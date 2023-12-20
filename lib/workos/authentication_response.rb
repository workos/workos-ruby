# frozen_string_literal: true
# typed: true

module WorkOS
  # The AuthenticationResponse class represents an Authentication Response as well as an corresponding
  # response data that can later be appended on.
  class AuthenticationResponse
    include HashProvider
    extend T::Sig

    attr_accessor :user, :organization_id

    sig { params(authentication_response_json: String).void }
    def initialize(authentication_response_json)
      json = JSON.parse(authentication_response_json, symbolize_names: true)
      @user = WorkOS::User.new(json[:user].to_json)
      @organization_id = T.let(json[:organization_id], T.nilable(String))
    end

    def to_json(*)
      {
        user: user.to_json,
        organization_id: organization_id,
      }
    end
  end
end
