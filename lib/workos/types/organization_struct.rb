# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # This OrganizationStruct acts as a typed interface
    # for the Organization class
    class OrganizationStruct < T::Struct
      const :id, String
      const :name, String
      const :domains, T::Array[T.untyped]
    end
  end
end
