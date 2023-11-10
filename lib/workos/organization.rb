# frozen_string_literal: true
# typed: true

module WorkOS
  # The Organization class provides a lightweight wrapper around
  # a WorkOS Organization resource. This class is not meant to be instantiated
  # in user space, and is instantiated internally but exposed.
  class Organization
    include HashProvider
    extend T::Sig

    attr_accessor :id, :name, :created_at, :updated_at

    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)

      @id = T.let(raw.id, String)
      @name = T.let(raw.name, String)
      @created_at = T.let(raw.created_at, String)
      @updated_at = T.let(raw.updated_at, String)
    end

    def to_json(*)
      {
        id: id,
        name: name,
        created_at: created_at,
        updated_at: updated_at,
      }
    end

    private

    sig do
      params(
        json_string: String,
      ).returns(WorkOS::Types::OrganizationStruct)
    end
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::OrganizationStruct.new(
        id: hash[:id],
        name: hash[:name],
        created_at: hash[:created_at],
        updated_at: hash[:updated_at],
      )
    end
  end
end
