# frozen_string_literal: true
# typed: true

module WorkOS
  # The DirectoryGroup class provides a lightweight wrapper around
  # a WorkOS DirectoryGroup resource. This class is not meant to be instantiated
  # in user space, and is instantiated internally but exposed.
  class DirectoryGroup < DeprecatedHashWrapper
    include HashProvider
    extend T::Sig

    attr_accessor :id, :directory_id, :idp_id, :name, :created_at, :updated_at, :raw_attributes

    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)

      @id = T.let(raw.id, String)
      @directory_id = T.let(raw.directory_id, String)
      @idp_id = T.let(raw.idp_id, String)
      @name = T.let(raw.name, String)
      @created_at = T.let(raw.created_at, String)
      @updated_at = T.let(raw.updated_at, String)
      @raw_attributes = raw.raw_attributes

      replace_without_warning(to_json)
    end

    def to_json(*)
      {
        id: id,
        directory_id: directory_id,
        idp_id: idp_id,
        name: name,
        created_at: created_at,
        updated_at: updated_at,
        raw_attributes: raw_attributes,
      }
    end

    private

    sig do
      params(
        json_string: String,
      ).returns(WorkOS::Types::DirectoryGroupStruct)
    end
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::DirectoryGroupStruct.new(
        id: hash[:id],
        directory_id: hash[:directory_id],
        idp_id: hash[:idp_id],
        name: hash[:name],
        created_at: hash[:created_at],
        updated_at: hash[:updated_at],
        raw_attributes: hash[:raw_attributes],
      )
    end
  end
end
