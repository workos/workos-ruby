# frozen_string_literal: true
# typed: true

module WorkOS
  # The OrganizationMembership class provide a lightweight wrapper around a WorkOS OrganizationMembership
  # resource. This class is not meant to be instantiated in a user space,
  # and is instantiated internally but exposed.
  class OrganizationMembership
    include HashProvider
    extend T::Sig

    attr_accessor :id, :user_id, :organization_id, :created_at, :updated_at

    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)

      @id = T.let(raw.id, String)
      @user_id = T.let(raw.user_id, String)
      @organization_id = raw.organization_id
      @created_at = T.let(raw.created_at, String)
      @updated_at = T.let(raw.updated_at, String)
    end

    def to_json(*)
      {
        id: id,
        user_id: user_id,
        organization_id: organization_id,
        created_at: created_at,
        updated_at: updated_at,
      }
    end

    private

    sig { params(json_string: String).returns(WorkOS::Types::UserStruct) }
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::OrganizationMembershipStruct.new(
        id: hash[:id],
        user_id: hash[:user_id],
        organization_id: hash[:organization_id],
        created_at: hash[:created_at],
        updated_at: hash[:updated_at],
      )
    end
  end
end
