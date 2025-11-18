# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'securerandom'

module WorkOS
  # The Audit Logs module provides convenience methods for working with the
  # WorkOS Audit Logs platform. You'll need a valid API key.
  module AuditLogs
    class << self
      include Client

      # Create an Audit Log Event.
      #
      # @param [String] organization An Organization ID
      # @param [Hash] event An Audit Log Event
      # @param [String] idempotency_key An idempotency key
      #
      # @return [nil]
      def create_event(organization:, event:, idempotency_key: nil)
        # Auto-generate idempotency key if not provided
        idempotency_key = SecureRandom.uuid if idempotency_key.nil?

        request = post_request(
          path: '/audit_logs/events',
          auth: true,
          idempotency_key: idempotency_key,
          body: {
            organization_id: organization,
            event: event,
          },
        )

        execute_request(request: request, retries: 3)
      end

      # Create an Export of Audit Log Events.
      #
      # @param [String] organization An Organization ID
      # @param [String] range_start ISO-8601 datetime
      # @param [String] range_end ISO-8601 datetime
      # @param [Array<String>] actions A list of actions to filter by
      # @param [Array<String>] @deprecated use `actor_names` instead
      # @param [Array<String>] actor_names A list of actor names to filter by
      # @param [Array<String>] actor_ids A list of actor ids to filter by
      # @param [Array<String>] targets A list of target types to filter by
      #
      # @return [WorkOS::AuditLogExport]
      def create_export(organization:, range_start:, range_end:, actions: nil, # rubocop:disable Metrics/ParameterLists
                        actors: nil, targets: nil, actor_names: nil, actor_ids: nil)
        body = {
          organization_id: organization,
          range_start: range_start,
          range_end: range_end,
        }

        body['actions'] = actions unless actions.nil?
        body['actors'] = actors unless actors.nil?
        body['actor_names'] = actor_names unless actor_names.nil?
        body['actor_ids'] = actor_ids unless actor_ids.nil?
        body['targets'] = targets unless targets.nil?

        request = post_request(
          path: '/audit_logs/exports',
          auth: true,
          body: body,
        )

        response = execute_request(request: request)

        WorkOS::AuditLogExport.new(response.body)
      end

      # Retrieves an Export of Audit Log Events
      #
      # @param [String] id An Audit Log Export ID
      #
      # @return [WorkOS::AuditLogExport]
      def get_export(id:)
        request = get_request(
          auth: true,
          path: "/audit_logs/exports/#{id}",
        )

        response = execute_request(request: request)

        WorkOS::AuditLogExport.new(response.body)
      end
    end
  end
end
