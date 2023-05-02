# frozen_string_literal: true
# typed: true

require 'net/http'
require 'uri'

module WorkOS
  # The Audit Logs module provides convenience methods for working with the
  # WorkOS Audit Logs platform. You'll need a valid API key.
  module AuditLogs
    class << self
      extend T::Sig
      include Client

      # Create an Audit Log Event.
      #
      # @param [String] organization An Organization ID
      # @param [Hash] event An Audit Log Event
      # @param [String] idempotency_key An idempotency key
      #
      # @return [nil]
      sig do
        params(
          organization: String,
          event: Hash,
          idempotency_key: T.nilable(String),
        ).void
      end
      def create_event(organization:, event:, idempotency_key: nil)
        request = post_request(
          path: '/audit_logs/events',
          auth: true,
          idempotency_key: idempotency_key,
          body: {
            organization_id: organization,
            event: event,
          },
        )

        execute_request(request: request)
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
      sig do
        params(
          organization: String,
          range_start: String,
          range_end: String,
          actions: T.nilable(T::Array[String]),
          actors: T.nilable(T::Array[String]),
          actor_names: T.nilable(T::Array[String]),
          actor_ids: T.nilable(T::Array[String]),
          targets: T.nilable(T::Array[String]),
        ).returns(WorkOS::AuditLogExport)
      end
      def create_export(organization:, range_start:, range_end:, actions: nil, actors: nil, actor_names: nil, actor_ids: nil, targets: nil)
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
      sig do
        params(
          id: String,
        ).returns(WorkOS::AuditLogExport)
      end
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
