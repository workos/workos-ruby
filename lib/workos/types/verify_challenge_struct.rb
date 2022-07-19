# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # This VerifyChallengeStruct acts as a typed interface
    # for the VerifyChallenge class
    class VerifyChallengeStruct < T::Struct
      const :challenge, T.nilable(T::Hash[Symbol, Object])
      const :valid, T::Boolean
    end
  end
end
