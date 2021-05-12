# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # The ProfileAndTokenStruct acts as a typed interface
    # for the ProfileAndToken class
    class ProfileAndTokenStruct < T::Struct
      const :access_token, String
      const :profile, ProfileStruct
    end
  end
end
