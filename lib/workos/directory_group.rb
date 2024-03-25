# frozen_string_literal: true

module WorkOS
  # The DirectoryGroup class provides a lightweight wrapper around
  # a WorkOS DirectoryGroup resource. This class is not meant to be instantiated
  # in user space, and is instantiated internally but exposed.
  class DirectoryGroup < DeprecatedHashWrapper
    include HashProvider

    attr_accessor :id, :directory_id, :idp_id, :name, :created_at, :updated_at,
                  :raw_attributes, :organization_id

    def initialize(json)
      hash = JSON.parse(json, symbolize_names: true)

      @id = hash[:id]
      @directory_id = hash[:directory_id]
      @organization_id = hash[:organization_id]
      @idp_id = hash[:idp_id]
      @name = hash[:name]
      @created_at = hash[:created_at]
      @updated_at = hash[:updated_at]
      @raw_attributes = hash[:raw_attributes]

      replace_without_warning(to_json)
    end

    def to_json(*)
      {
        id: id,
        directory_id: directory_id,
        organization_id: organization_id,
        idp_id: idp_id,
        name: name,
        created_at: created_at,
        updated_at: updated_at,
        raw_attributes: raw_attributes,
      }
    end
  end
end
