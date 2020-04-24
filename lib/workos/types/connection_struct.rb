# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # This ConnectoinStruct acts as a typed interface
    # for the Connection class
    class ConnectionStruct < T::Struct
      const :id, String
      const :name, String
      const :connection_type, String
      const :domains, T::Array[T.untyped]
    end
  end
end
