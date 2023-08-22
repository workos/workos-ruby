# frozen_string_literal: true
# typed: true

module WorkOS
  module Types
    # This MagicAuthChallengeStruct acts as a typed interface for the
    # MagicAuthChallenge class
    class MagicAuthChallengeStruct < T::Struct
      const :id, String
    end
  end
end
