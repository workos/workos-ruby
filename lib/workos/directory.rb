# frozen_string_literal: true
# typed: true

module WorkOS
  # The Directory class provides a lightweight wrapper around
  # a WorkOS Directory resource. This class is not meant to be instantiated
  # in user space, and is instantiated internally but exposed.
  class Directory
    extend T::Sig

    attr_accessor :id, :domain, :name, :type, :state, :organization_id, :created_at, :updated_at

    # rubocop:disable Metrics/AbcSize
    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)

      @id = T.let(raw.id, String)
      @name = T.let(raw.name, String)
      @domain = raw.domain
      @type = T.let(raw.type, String)
      @state = T.let(raw.state, String)
      @organization_id = T.let(raw.organization_id, String)
      @created_at = T.let(raw.created_at, String)
      @updated_at = T.let(raw.updated_at, String)
    end
    # rubocop:enable Metrics/AbcSize

    def to_json(*)
      {
        id: id,
        name: name,
        domain: domain,
        type: type,
        state: state,
        organization_id: organization_id,
        created_at: created_at,
        updated_at: updated_at,
      }
    end

    private

    sig do
      params(
        json_string: String,
      ).returns(WorkOS::Types::DirectoryStruct)
    end
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::DirectoryStruct.new(
        id: hash[:id],
        name: hash[:name],
        domain: hash[:domain],
        type: hash[:type],
        state: hash[:state],
        organization_id: hash[:organization_id],
        created_at: hash[:created_at],
        updated_at: hash[:updated_at],
      )
    end
  end
end
