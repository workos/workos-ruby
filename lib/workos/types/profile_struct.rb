# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # The ProfileStruct acts as a typed interface
    # for the Profile class
    class ProfileStruct < T::Struct
      const :id, String
      const :email, String
      const :first_name, T.nilable(String)
      const :last_name, T.nilable(String)
      const :connection_id, String
      const :connection_type, String
      const :idp_id, T.nilable(String)
      const :raw_attributes, T::Hash[Symbol, Object]
    end
  end
end
