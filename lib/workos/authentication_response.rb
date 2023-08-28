# frozen_string_literal: true
# typed: true

module WorkOS
  # The AuthenticationResponse class represents a User as well as an corresponding
  # response data that can later be appended on.
  class AuthenticationResponse
    include HashProvider
    extend T::Sig

    attr_accessor :user

    sig { params(authenitcation_response_json: String).void }
    def initialize(authenitcation_response_json)
      json = JSON.parse(authenitcation_response_json, symbolize_names: true)
      @user = WorkOS::User.new(json[:user].to_json)
    end

    def to_json(*)
      {
        user: user.to_json,
      }
    end
  end
end
