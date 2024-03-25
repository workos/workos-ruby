# frozen_string_literal: true

module WorkOS
  # The AuditLogExport class represents the WorkOS entity created when exporting Audit Log Events.
  class AuditLogExport
    include HashProvider

    attr_accessor :object, :id, :state, :url, :created_at, :updated_at

    def initialize(json)
      hash = JSON.parse(json, symbolize_names: true)

      @object = hash[:object]
      @id = hash[:id]
      @state = hash[:state]
      @url = hash[:url]
      @created_at = hash[:created_at]
      @updated_at = hash[:updated_at]
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
  end
end
