# frozen_string_literal: true

module WorkOS
  # The FeatureFlag class provides a lightweight wrapper around
  # a WorkOS Feature Flag resource. This class is not meant to be instantiated
  # in user space, and is instantiated internally but exposed.
  class FeatureFlag
    include HashProvider

    attr_accessor :id, :name, :slug, :description, :created_at, :updated_at

    def initialize(json)
      hash = JSON.parse(json, symbolize_names: true)

      @id = hash[:id]
      @name = hash[:name]
      @slug = hash[:slug]
      @description = hash[:description]
      @created_at = hash[:created_at]
      @updated_at = hash[:updated_at]
    end

    def to_json(*)
      {
        id: id,
        name: name,
        slug: slug,
        description: description,
        created_at: created_at,
        updated_at: updated_at,
      }
    end
  end
end
