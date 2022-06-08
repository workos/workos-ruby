# frozen_string_literal: true
# typed: false

module WorkOS
  # The Challnge class provides a lightweight wrapper around
  # a WorkOS DirectoryUser resource. This class is not meant to be instantiated
  # in DirectoryUser space, and is instantiated internally but exposed.
  class Challenge
    include HashProvider
    extend T::Sig

    attr_accessor :id, :object, :expires_at, :code, :authentication_factor_id, :updated_at, :created_at

    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)
      @id = T.let(raw.id, String)
      @object = T.let(raw.object, String)
      @expires_at = T.let(raw.expires_at, String)
      @code = raw.code
      @authentication_factor_id = T.let(raw.authentication_factor_id, String)
      @created_at = T.let(raw.created_at, String)
      @updated_at = T.let(raw.updated_at, String)
    end

    def to_json(*)
      {
        id: id,
        object: object,
        expires_at: expires_at,
        code: code,
        authentication_factor_id: authentication_factor_id,
        created_at: created_at,
        updated_at: updated_at,
      }
    end

    private

    sig { params(json_string: String).returns(WorkOS::Types::ChallengeStruct) }
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::ChallengeStruct.new(
        id: hash[:id],
        object: hash[:object],
        expires_at: hash[:expires_at],
        code: hash[:code],
        authentication_factor_id: hash[:authentication_factor_id],
        created_at: hash[:created_at],
        updated_at: hash[:updated_at],
      )
    end
  end
end
