# frozen_string_literal: true
# typed: true

module WorkOS
  # The DirectoryGroup class provides a lightweight wrapper around
  # a WorkOS DirectoryGroup resource. This class is not meant to be instantiated
  # in user space, and is instantiated internally but exposed.
  class DirectoryGroup < DeprecatedHashWrapper
    include HashProvider
    extend T::Sig

    attr_accessor :id, :name, :custom_attributes, :raw_attributes

    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)

      @id = T.let(raw.id, String)
      @name = T.let(raw.name, String)

      replace_without_warning(to_json)
    end

    def to_json(*)
      {
        id: id,
        name: name,
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
        name: hash[:name],
      )
    end
  end
end
