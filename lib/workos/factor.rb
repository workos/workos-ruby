module WorkOS
    class Factor
      extend T::Sig
  
      attr_accessor :id, :environment_id, :object, :type, :sms, :totp, :updated_at, :created_at

    # rubocop:disable Metrics/AbcSize
    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)
      @id = T.let(raw.id, String)
      @environment_id = T.let(raw.environment_id, String)
      @object = T.let(raw.object, String)
      @type = T.let(raw.type, String)
      @created_at = T.let(raw.created_at, String)
      @updated_at = T.let(raw.updated_at, String)
      if raw.type == 'totp'
        @totp = T.let(raw.totp, Hash)
      elsif raw.type == 'sms'
        @sms = T.let(raw.sms, Hash) 
      end
    end
    # rubocop:enable Metrics/AbcSize

    def to_json(*)
      {
        id: id,
        environment_id: environment_id,
        object: object,
        type: type,
        totp: totp,
        sms: sms,
        created_at: created_at,
        updated_at: updated_at,
      }
    end

    private

    sig { params(json_string: String).returns(WorkOS::Types::FactorStruct) }
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::FactorStruct.new(
        id: hash[:id],
        environment_id: hash[:environment_id],
        object: hash[:object],
        type: hash[:type],
        totp: hash[:totp],
        sms: hash[:sms],
        created_at: hash[:created_at],
        updated_at: hash[:updated_at],
      )
      end
    end
  end
  