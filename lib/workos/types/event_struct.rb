# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # The EventStruct acts as a typed interface
    # for the Event class
    class EventStruct < T::Struct
      const :id, String
      const :event, String
      const :data, T::Hash[Symbol, T.untyped]
      const :created_at, String
    end
  end
end
