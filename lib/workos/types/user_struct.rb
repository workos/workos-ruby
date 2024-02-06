# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # This UserStruct acts as a typed interface for the User class
    class UserStruct < T::Struct
      const :id, String
      const :email, String
      const :first_name, T.nilable(String)
      const :last_name, T.nilable(String)
      const :email_verified, T::Boolean
      const :profile_picture_url, T.nilable(String)
      const :created_at, String
      const :updated_at, String
    end
  end
end
