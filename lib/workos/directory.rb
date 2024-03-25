# frozen_string_literal: true

module WorkOS
  # The Directory class provides a lightweight wrapper around
  # a WorkOS Directory resource. This class is not meant to be instantiated
  # in user space, and is instantiated internally but exposed.
  class Directory
    include HashProvider

    attr_accessor :id, :domain, :name, :type, :state, :organization_id, :created_at, :updated_at

    def initialize(json)
      hash = JSON.parse(json, symbolize_names: true)

      @id = hash[:id]
      @name = hash[:name]
      @domain = hash[:domain]
      @type = hash[:type]
      @state = hash[:state]
      @organization_id = hash[:organization_id]
      @created_at = hash[:created_at]
      @updated_at = hash[:updated_at]
    end

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
  end
end
