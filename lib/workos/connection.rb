# frozen_string_literal: true

module WorkOS
  # The Connection class provides a lightweight wrapper around
  # a WorkOS Connection resource. This class is not meant to be instantiated
  # in user space, and is instantiated internally but exposed.
  # Note: status is deprecated - use state instead
  class Connection
    include HashProvider

    attr_accessor :id, :name, :connection_type, :domains, :organization_id,
                  :state, :status, :created_at, :updated_at

    # rubocop:disable Metrics/AbcSize
    def initialize(json)
      hash = JSON.parse(json, symbolize_names: true)

      @id = hash[:id]
      @name = hash[:name]
      @connection_type = hash[:connection_type]
      @domains = hash[:domains]
      @organization_id = hash[:organization_id]
      @state = hash[:state]
      @status = hash[:status]
      @created_at = hash[:created_at]
      @updated_at = hash[:updated_at]
    end
    # rubocop:enable Metrics/AbcSize

    def to_json(*)
      {
        id: id,
        name: name,
        connection_type: connection_type,
        domains: domains,
        organization_id: organization_id,
        state: state,
        status: status,
        created_at: created_at,
        updated_at: updated_at,
      }
    end
  end
end
