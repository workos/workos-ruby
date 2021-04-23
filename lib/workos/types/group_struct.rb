# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # This GroupStruct acts as a typed interface
    # for the Group class
    class GroupStruct < T::Struct
      const :id, String
      const :name, String
    end
  end
end
