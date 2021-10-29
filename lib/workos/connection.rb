# frozen_string_literal: true
# typed: true

module WorkOS
  # The Connection class provides a lightweight wrapper around
  # a WorkOS Connection resource. This class is not meant to be instantiated
  # in user space, and is instantiated internally but exposed.
  # Note: status is deprecated - use state instead
  class Connection
    extend T::Sig

    attr_accessor :id, :name, :connection_type, :domains, :organization_id,
                  :state, :status, :created_at, :updated_at

    # rubocop:disable Metrics/AbcSize
    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)

      @id = T.let(raw.id, String)
      @name = T.let(raw.name, String)
      @connection_type = T.let(raw.connection_type, String)
      @domains = T.let(raw.domains, Array)
      @organization_id = raw.organization_id
      @state = T.let(raw.state, String)
      @status = T.let(raw.status, String)
      @created_at = T.let(raw.created_at, String)
      @updated_at = T.let(raw.updated_at, String)
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

    private

    sig { params(json_string: String).returns(WorkOS::Types::ConnectionStruct) }
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::ConnectionStruct.new(
        id: hash[:id],
        name: hash[:name],
        connection_type: hash[:connection_type],
        domains: hash[:domains],
        organization_id: hash[:organization_id],
        state: hash[:state],
        status: hash[:status],
        created_at: hash[:created_at],
        updated_at: hash[:updated_at],
      )
    end
  end
end
