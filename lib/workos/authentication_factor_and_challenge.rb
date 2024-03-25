# frozen_string_literal: true

module WorkOS
  # The AuthenticationFactorAndChallenge class represents
  # an authentication factor and challenge for a given user.
  class AuthenticationFactorAndChallenge
    include HashProvider

    attr_accessor :authentication_factor, :authentication_challenge

    def initialize(authentication_response_json)
      json = JSON.parse(authentication_response_json, symbolize_names: true)
      @authentication_factor = WorkOS::Factor.new(
        json[:authentication_factor].to_json,
      )
      @authentication_challenge = WorkOS::Challenge.new(
        json[:authentication_challenge].to_json,
      )
    end

    def to_json(*)
      {
        authentication_factor: authentication_factor.to_json,
        authentication_challenge: authentication_challenge.to_json,
      }
    end
  end
end
