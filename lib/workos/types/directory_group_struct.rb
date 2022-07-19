# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # This DirectoryGroupStruct acts as a typed interface
    # for the DirectoryGroup class
    class DirectoryGroupStruct < T::Struct
      const :id, String
      const :directory_id, String
      const :organization_id, T.nilable(String)
      const :idp_id, String
      const :name, String
      const :created_at, String
      const :updated_at, String
      const :raw_attributes, T::Hash[Symbol, Object]
    end
  end
end
