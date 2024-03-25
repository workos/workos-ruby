# frozen_string_literal: true

module WorkOS
  # The VerifyChallenge class provides a lightweight wrapper around
  # a WorkOS Authentication Challenge resource.
  class VerifyChallenge
    include HashProvider

    attr_accessor :challenge, :valid

    def initialize(json)
      hash = JSON.parse(json, symbolize_names: true)

      @challenge = hash[:challenge]
      @valid = hash[:valid]
    end

    def to_json(*)
      {
        challenge: challenge,
        valid: valid,
      }
    end
  end
end
