# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # This DirectoryGroupStruct acts as a typed interface
    # for the DirectoryGroup class
    class DirectoryGroupStruct < T::Struct
      const :id, String
      const :name, String
    end
  end
end
