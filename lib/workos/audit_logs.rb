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

      # Create an Audit Log event.
      #
      # @param [String] organization An Organization ID
      # @param [Hash] event An event hash
      # @param [String] idempotency_key An idempotency key
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
      end
    end
  end
end
