# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # This ChallgengeStruct acts as a typed interface
    # for the Factor class
    class ChallengeStruct < T::Struct
      const :id, String
      const :object, String
      const :expires_at, String
      const :code, T.nilable(String)
      const :authentication_factor_id, String
      const :created_at, String
      const :updated_at, String
    end
  end
end
