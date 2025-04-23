# frozen_string_literal: true

require 'net/http'

module WorkOS
  # The Widgets module provides resource methods for working with the Widgets APIs
  module Widgets
    class << self
      include Client

      WIDGET_SCOPES = WorkOS::Types::WidgetScope::ALL

      # Generate a widget token.
      #
      # @param [String] organization_id The ID of the organization to generate the token for.
      # @param [String] user_id The ID of the user to generate the token for.
      # @param [WidgetScope[]] The scopes to generate the token for.
      def get_token(organization_id:, user_id:, scopes:)
        validate_scopes(scopes)

        request = post_request(
          auth: true,
          body: {
            organization_id: organization_id,
            user_id: user_id,
            scopes: scopes,
          },
          path: '/widgets/token',
        )

        response = execute_request(request: request)

        JSON.parse(response.body)['token']
      end

      private

      def validate_scopes(scopes)
        return if scopes.all? { |scope| WIDGET_SCOPES.include?(scope) }

        raise ArgumentError, 'scopes contains an invalid value.' \
        " Every item in `scopes` must be in #{WIDGET_SCOPES}"
      end
    end
  end
end
