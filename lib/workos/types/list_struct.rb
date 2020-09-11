# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # ListStruct acts as a typed interface to expose lists of data and related
    # metadata
    class ListStruct < T::Struct
      const :data, T::Array[T.untyped]
      const :list_metadata, T::Hash[String, T.nilable(String)]
    end
  end
end
