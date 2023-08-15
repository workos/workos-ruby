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
      const :email_verified_at, T.nilable(String)
      const :google_oauth_profile_id, T.nilable(String)
      const :sso_profile_id, T.nilable(String)
      const :user_type, String
      const :created_at, String
      const :updated_at, String
    end
  end
end
