# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # The DirectoryUserStruct acts as a typed interface
    # for the DirectoryUser class
    class DirectoryUserStruct < T::Struct
      const :id, String
      const :directory_id, String
      const :organization_id, T.nilable(String)
      const :idp_id, String
      const :emails, T::Array[T.untyped]
      const :first_name, T.nilable(String)
      const :last_name, T.nilable(String)
      const :username, T.nilable(String)
      const :state, T.nilable(String)
      const :groups, T::Array[T.untyped]
      const :custom_attributes, T::Hash[Symbol, T.untyped]
      const :raw_attributes, T::Hash[Symbol, Object]
    end
  end
end
