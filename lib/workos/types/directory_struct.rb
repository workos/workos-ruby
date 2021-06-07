# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # This DirectoryStruct acts as a typed interface
    # for the Directory class
    class DirectoryStruct < T::Struct
      const :id, String
      const :name, String
      const :domain, String
      const :type, String
      const :state, String
      const :organization_id, String
    end
  end
end
