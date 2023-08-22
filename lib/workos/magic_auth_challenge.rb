# frozen_string_literal: true
# typed: true

module WorkOS
  # The MagicAuthChallenge class provides a lightweight wrapper around a WorkOS
  # MagicAuthChallenge resource. This class is not meant to be instantiated in
  # user space, and is instantiated internally but exposed.
  class MagicAuthChallenge
    include HashProvider
    extend T::Sig

    attr_accessor :id

    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)

      @id = T.let(raw.id, String)
    end

    def to_json(*)
      {
        id: id,
      }
    end

    private

    sig { params(json_string: String).returns(WorkOS::Types::MagicAuthChallengeStruct) }
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::MagicAuthChallengeStruct.new(
        id: hash[:id],
      )
    end
  end
end
