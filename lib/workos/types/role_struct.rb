# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # This OrganizationMembershipStruct acts as a typed interface for the OrganizationMembership class
    class RoleStruct < T::Struct
      const :slug, String
    end
  end
end
