# frozen_string_literal: true
# typed: strict

module WorkOS
    module Types
        # This VerifyFactorStruct acts as a typed interface
        # for the Factor class
        class VerifyFactorStruct < T::Struct
            const :challenge, T.nilable(Hash)
            const :valid, T.nilable(TrueClass)
            const :code, T.nilable(String)
            const :message, T.nilable(String)
        end
    end
end
  
