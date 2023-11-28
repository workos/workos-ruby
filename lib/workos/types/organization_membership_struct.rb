# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # This OrganizationMembershipStruct acts as a typed interface for the OrganizationMembership class
    class OrganizationMembershipStruct < T::Struct
      const :id, String
      const :user_id, String
      const :organization_id, String
      const :created_at, String
      const :updated_at, String
    end
  end
end
