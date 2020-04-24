# frozen_string_literal: true
# typed: true

require 'net/http'
require 'uri'

module WorkOS
  # The Audit Trail module provides convenience methods for working with the
  # WorkOS Audit Trail platform. You'll need a valid API key.
  #
  # @see https://docs.workos.com/audit-trail/overview
  module AuditTrail
    class << self
      extend T::Sig
      include Base
      include Client

      # Create an Audit Trail event.
      #
      # @param [Hash] event An event hash
      # @option event [String] group A single organization containing related
      #  members. This will normally be the customer of a vendor's application.
      # @option event [String] location Identifier for where the event
      #  originated. This will be an IP address (IPv4 or IPv6), hostname, or
      #  device ID.
      # @option event [String] action Specific activity performed by the actor.
      # @option event [String] action_type Corresponding CRUD category of the
      #  event. Can be one of C, R, U, or D.
      # @option event [String] actor_name Display name of the entity performing
      #  the action.
      # @option event [String] actor_id Unique identifier of the entity
      #  performing the action.
      # @option event [String] target_name Display name of the object or
      #  resource that is being acted upon.
      # @option event [String] target_id Unique identifier of the object or
      #  resource being acted upon.
      # @option event [String] occurred_at ISO-8601 datetime at which the event
      #  happened, with millisecond precision.
      # @option event [Hash] metadata Arbitrary key-value data containing
      #  information associated with the event. Note: There is a limit of 50
      #  keys. Key names can be up to 40 characters long, and values can be up
      #  to 500 characters long.
      # @param [String] idempotency_key An idempotency key
      sig do
        params(
          event: Hash,
          idempotency_key: T.nilable(String),
        ).returns(::T.untyped)
      end

      def create_event(event:, idempotency_key: nil)
        request = post_request(
          path: '/events',
          idempotency_key: idempotency_key,
          body: event,
        )

        execute_request(request: request)
      end
    end
  end
end
