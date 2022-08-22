# frozen_string_literal: true
# typed: true

require 'net/http'
require 'uri'

module WorkOS
  # The Audit Logs module provides convenience methods for working with the
  # WorkOS Audit Logs platform. You'll need a valid API key.
  #
  # @see https://docs.workos.com/audit-logs/overview
  module AuditLogs
    class << self
      extend T::Sig
      include Client

      # Create an Audit Log Event.
      sig do
        params(
          organization: String,
          event: Hash,
          idempotency_key: T.nilable(String),
        ).returns(::T.untyped)
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

        nil
      end

      # Create an export of Audit Log Events.
      sig do
        params(
          organization: String,
          range_start: String,
          range_end: String,
          actions: T.nilable(T::Array[String]),
          actors: T.nilable(T::Array[String]),
          targets: T.nilable(T::Array[String]),
        ).returns(WorkOS::AuditLogExport)
      end
      def create_export(organization:, range_start:, range_end:, actions: nil, actors: nil, targets: nil)
        body = {
          organization_id: organization,
          range_start: range_start,
          range_end: range_end,
        }

        body['actions'] = actions unless actions.nil?
        body['actors'] = actors unless actors.nil?
        body['targets'] = targets unless targets.nil?

        request = post_request(
          path: '/audit_logs/exports',
          auth: true,
          body: body,
        )

        response = execute_request(request: request)

        WorkOS::AuditLogExport.new(response.body)
      end

      # Retreives an export of Audit Log Events
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
