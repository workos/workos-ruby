# frozen_string_literal: true
# typed: true

module WorkOS
  # The Group class provides a lightweight wrapper around
  # a WorkOS Group resource. This class is not meant to be instantiated
  # in user space, and is instantiated internally but exposed.
  class Group
    extend T::Sig

    attr_accessor :id, :name

    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)

      @id = T.let(raw.id, String)
      @name = T.let(raw.name, String)
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
      ).returns(WorkOS::Types::GroupStruct)
    end
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::GroupStruct.new(
        id: hash[:id],
        name: hash[:name],
      )
    end
  end
end
