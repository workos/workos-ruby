# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # This InvitationStruct acts as a typed interface for the Invitation class
    class InvitationStruct < T::Struct
      const :id, String
      const :email, String
      const :state, String
      const :token, String
      const :organization_id, T.nilable(String)
      const :accepted_at, T.nilable(String)
      const :revoked_at, T.nilable(String)
      const :expires_at, String
      const :created_at, String
      const :updated_at, String
    end
  end
end
