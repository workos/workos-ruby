# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # The UserStruct acts as a typed interface
    # for the User class
    class UserStruct < T::Struct
      const :id, String
      const :emails, T::Array[T.untyped]
      const :first_name, T.nilable(String)
      const :last_name, T.nilable(String)
      const :username, T.nilable(String)
      const :state, T.nilable(String)
      const :raw_attributes, T::Hash[Symbol, Object]
    end
  end
end
