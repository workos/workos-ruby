# frozen_string_literal: true

module WorkOS
  module Types
    # ListStruct acts as an interface to expose lists of data and related
    # metadata
    class ListStruct
      attr_accessor :data, :list_metadata

      def initialize(data:, list_metadata:)
        @data = data
        @list_metadata = list_metadata
      end
    end
  end
end
