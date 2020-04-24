# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # The ProfileStruct acts as a typed interface
    # for the Profile class
    class ProfileStruct < T::Struct
      const :id, String
      const :email, String
      const :first_name, String
      const :last_name, String
      const :connection_type, String
      const :idp_id, String
    end
  end
end
