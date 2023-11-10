# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # This OrganizationStruct acts as a typed interface
    # for the Organization class
    class OrganizationStruct < T::Struct
      const :id, String
      const :name, String
      const :created_at, String
      const :updated_at, String
    end
  end
end
