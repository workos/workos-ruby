# frozen_string_literal: true

require 'net/http'

module WorkOS
  # The Events module provides convenience methods for working with the
  # WorkOS Events platform. You'll need a valid API key and be in the
  # Events beta to be able to access the API
  #
  module Events
    class << self
      include Client

      # Retrieve events.
      #
      # @param [Hash] options An options hash
      # @option options [String] event The type of event
      #  retrieved.
      # @option options [String] limit Maximum number of records to return.
      # @option options [String] after Pagination cursor to receive records
      #  after a provided Event ID.
      #
      # @return [Hash]
      def list_events(events:, options: {})
        response = execute_request(
          request: get_request(
            path: '/events',
            auth: true,
            params: {
              **options,
              events: events,
            },
          ),
        )

        parsed_response = JSON.parse(response.body)
        events = parsed_response['data'].map do |event|
          ::WorkOS::Event.new(event.to_json)
        end

        WorkOS::Types::ListStruct.new(
          data: events,
          list_metadata: parsed_response['list_metadata'],
        )
      end
    end
  end
end
