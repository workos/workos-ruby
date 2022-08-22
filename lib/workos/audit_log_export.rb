# frozen_string_literal: true
# typed: true

module WorkOS
  # The AuditLogExport class represents the WorkOS entity created when exporting Audit Log Events.
  class AuditLogExport
    include HashProvider
    extend T::Sig

    attr_accessor :object, :id, :state, :url, :created_at, :updated_at

    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)

      @object = T.let(raw.object, String)
      @id = T.let(raw.id, String)
      @state = T.let(raw.state, String)
      @url = raw.url
      @created_at = T.let(raw.created_at, String)
      @updated_at = T.let(raw.updated_at, String)
    end

    def to_json(*)
      {
        object: object,
        id: id,
        state: state,
        url: url,
        created_at: created_at,
        updated_at: updated_at,
      }
    end

    private

    sig do
      params(
        json_string: String,
      ).returns(WorkOS::Types::AuditLogExportStruct)
    end
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::AuditLogExportStruct.new(
        object: hash[:object],
        id: hash[:id],
        state: hash[:state],
        url: hash[:url],
        created_at: hash[:created_at],
        updated_at: hash[:updated_at],
      )
    end
  end
end
