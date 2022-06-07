# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # This FactorStruct acts as a typed interface
    # for the Factor class
    class FactorStruct < T::Struct
      const :id, String
      const :object, String
      const :type, String
      const :totp, T.nilable(T::Hash[Symbol, Object])
      const :sms, T.nilable(T::Hash[Symbol, Object])
      const :created_at, String
      const :updated_at, String
    end
  end
end
