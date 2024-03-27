# frozen_string_literal: true

module WorkOS
  # The OrganizationMembership class provides a lightweight wrapper around a WorkOS OrganizationMembership
  # resource. This class is not meant to be instantiated in a user space,
  # and is instantiated internally but exposed.
  class OrganizationMembership
    include HashProvider

    attr_accessor :id, :user_id, :organization_id, :status, :created_at, :updated_at

    def initialize(json)
      hash = JSON.parse(json, symbolize_names: true)

      @id = hash[:id]
      @user_id = hash[:user_id]
      @organization_id = hash[:organization_id]
      @status = hash[:status]
      @created_at = hash[:created_at]
      @updated_at = hash[:updated_at]
    end

    def to_json(*)
      {
        id: id,
        user_id: user_id,
        organization_id: organization_id,
        status: status,
        created_at: created_at,
        updated_at: updated_at,
      }
    end
  end
end
