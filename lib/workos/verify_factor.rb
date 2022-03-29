# frozen_string_literal: true
# typed: false

module WorkOS
  # The VerifyFactor class provides a lightweight wrapper around
  # a WorkOS DirectoryUser resource. This class is not meant to be instantiated
  # in DirectoryUser space, and is instantiated internally but exposed.
  class VerifyFactor
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

    sig { params(json_string: String).returns(WorkOS::Types::VerifyFactorStruct) }
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::VerifyFactorStruct.new(
        challenge: hash[:challenge],
        valid: hash[:valid],
      )
    end
  end
end
