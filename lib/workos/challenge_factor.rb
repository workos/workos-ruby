module WorkOS
    class ChallengeFactor
      extend T::Sig
  
      attr_accessor :id, :object, :expires_at, :code, :authentication_factor_id, :updated_at, :created_at, 

    # rubocop:disable Metrics/AbcSize
    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)
      puts raw

      @id = T.let(raw.id, String)
      @object = T.let(raw.object, String)
      @expires_at = T.let(raw.expires_at, String)
      @code = T.let(raw.code, String)
      @authentication_factor_id = T.let(raw.authentication_factor_id, String)
      @created_at = T.let(raw.created_at, String)
      @updated_at = T.let(raw.updated_at, String)
    end
    # rubocop:enable Metrics/AbcSize

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

    sig { params(json_string: String).returns(WorkOS::Types::ChallengeFactorStruct) }
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::ChallengeFactorStruct.new(
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
end
  