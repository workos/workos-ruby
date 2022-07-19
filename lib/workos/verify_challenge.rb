# frozen_string_literal: true
# typed: false

module WorkOS
  # The VerifyChallenge class provides a lightweight wrapper around
  # a WorkOS Authentication Challenge resource.
  class VerifyChallenge
    include HashProvider
    extend T::Sig

    attr_accessor :challenge, :valid

    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)
      @challenge = T.let(raw.challenge, Hash)
      @valid = raw.valid
    end

    def to_json(*)
      {
        challenge: challenge,
        valid: valid,
      }
    end

    private

    sig { params(json_string: String).returns(WorkOS::Types::VerifyChallengeStruct) }
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::VerifyChallengeStruct.new(
        challenge: hash[:challenge],
        valid: hash[:valid],
      )
    end
  end
end
