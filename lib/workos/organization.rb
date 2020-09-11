# frozen_string_literal: true
# typed: true

require 'json'

module WorkOS
  # The Organization class provides a lightweight wrapper around
  # a WorkOS Organization resource. This class is not meant to be instantiated
  # in user space, and is instantiated internally but exposed.
  class Organization
    extend T::Sig

    attr_accessor :id, :domains, :name

    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)

      @id = T.let(raw.id, String)
      @name = T.let(raw.name, String)
      @domains = T.let(raw.domains, Array)
    end

    def to_json(*)
      {
        id: id,
        name: name,
        domains: domains,
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
        domains: hash[:domains],
      )
    end
  end
end
