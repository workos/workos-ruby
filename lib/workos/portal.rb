# frozen_string_literal: true
# typed: true

require 'net/http'

module WorkOS
  # The Portal module provides resource methods for working with the Admin
  # Portal product
  module Portal
    class << self
      extend T::Sig
      include Client

      GENERATE_LINK_INTENTS = WorkOS::Types::Intent.values.map(&:serialize).
                              freeze

      # Generate a link to grant access to an organization's Admin Portal
      #
      # @param [String] intent The access scope for the generated Admin Portal
      #  link. Valid values are: ["sso", "dsync"]
      # @param [String] organization The ID of the organization the Admin
      #  Portal link will be generated for.
      # @param [String] The URL that the end user will be redirected to upon
      #  exiting the generated Admin Portal. If none is provided, the default
      #  redirect link set in your WorkOS Dashboard will be used.
      # @param [String] The URL to which WorkOS will redirect users to upon
      #  successfully setting up Single Sign On or Directory Sync.
      sig do
        params(
          intent: String,
          organization: String,
          return_url: T.nilable(String),
          success_url: T.nilable(String),
        ).returns(String)
      end
      def generate_link(intent:, organization:, return_url: nil, success_url: nil)
        validate_intent(intent)

        request = post_request(
          auth: true,
          body: {
            intent: intent,
            organization: organization,
            return_url: return_url,
            success_url: success_url,
          },
          path: '/portal/generate_link',
        )

        response = execute_request(request: request)

        JSON.parse(response.body)['link']
      end

      private

      sig { params(intent: String).void }
      def validate_intent(intent)
        return if GENERATE_LINK_INTENTS.include?(intent)

        raise ArgumentError, "#{intent} is not a valid value." \
        " `intent` must be in #{GENERATE_LINK_INTENTS}"
      end
    end
  end
end
