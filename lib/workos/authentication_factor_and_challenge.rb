# frozen_string_literal: true
# typed: true

module WorkOS
  # The AuthenticationFactorAndChallenge class represents
  # an authentication factor and challenge for a given user.
  class AuthenticationFactorAndChallenge
    include HashProvider
    extend T::Sig

    attr_accessor :factor, :challenge

    sig { params(authentication_response_json: String).void }
    def initialize(authentication_response_json)
      json = JSON.parse(authentication_response_json, symbolize_names: true)
      @factor = WorkOS::Factor.new(
        json[:factor].to_json,
      )
      @challenge = WorkOS::Challenge.new(
        json[:challenge].to_json,
      )
    end

    def to_json(*)
      {
        factor: factor.to_json,
        challenge: challenge.to_json,
      }
    end
  end
end
