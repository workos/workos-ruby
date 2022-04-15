# frozen_string_literal: true
# typed: false

module WorkOS
  # The Factor class provides a lightweight wrapper around
  # a WorkOS DirectoryUser resource. This class is not meant to be instantiated
  # in DirectoryUser space, and is instantiated internally but exposed.
  class Factor
    include HashProvider
    # rubocop:disable Metrics/AbcSize
    extend T::Sig
    attr_accessor :id, :environment_id, :object, :type, :sms, :totp, :updated_at, :created_at

    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)
      @id = T.let(raw.id, String)
      @environment_id = T.let(raw.environment_id, String)
      @object = T.let(raw.object, String)
      @type = T.let(raw.type, String)
      @created_at = T.let(raw.created_at, String)
      @updated_at = T.let(raw.updated_at, String)
      @totp = raw.totp
      @sms = raw.sms
    end

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
    # rubocop:enable Metrics/AbcSize
  end
end
