# frozen_string_literal: true
# typed: true

require 'net/http'

module WorkOS
  # The Portal module provides resource methods for working with the Admin
  # Portal product
  module Portal
    class << self
      extend T::Sig
      include Base
      include Client

      GENERATE_LINK_INTENTS = WorkOS::Types::Intent.values.map(&:serialize).
                              freeze

      # Create an organization
      #
      # @param [Array<String>] domains List of domains that belong to the
      #  organization
      # @param [String] name A unique, descriptive name for the organization
      sig do
        params(
          domains: T::Array[String],
          name: String,
        ).returns(WorkOS::Organization)
      end
      def create_organization(domains:, name:)
        request = post_request(
          auth: true,
          body: { domains: domains, name: name },
          path: '/organizations',
        )

        response = execute_request(request: request)
        check_and_raise_organization_error(response: response)

        WorkOS::Organization.new(response.body)
      end

      # Generate a link to grant access to an organization's Admin Portal
      #
      # @param [String] intent The access scope for the generated Admin Portal
      #  link. Valid values are: ["sso", "dsync"]
      # @param [String] organization The ID of the organization the Admin
      #  Portal link will be generated for.
      # @param [String] The URL that the end user will be redirected to upon
      #  exiting the generated Admin Portal. If none is provided, the default
      #  redirect link set in your WorkOS Dashboard will be used.
      sig do
        params(
          intent: String,
          organization: String,
          return_url: T.nilable(String),
        ).returns(String)
      end
      def generate_link(intent:, organization:, return_url: nil)
        validate_intent(intent)

        request = post_request(
          auth: true,
          body: {
            intent: intent,
            organization: organization,
            return_url: return_url,
          },
          path: '/portal/generate_link',
        )

        response = execute_request(request: request)

        JSON.parse(response.body)['link']
      end

      # Retrieve a list of organizations that have connections configured
      # within your WorkOS dashboard.
      #
      # @param [Array<String>] domains Filter organizations to only return those
      #  that are associated with the provided domains.
      # @param [String] before A pagination argument used to request
      #  organizations before the provided Organization ID.
      # @param [String] after A pagination argument used to request
      #  organizations after the provided Organization ID.
      # @param [Integer] limit A pagination argument used to limit the number
      #  of listed Organizations that are returned.
      sig do
        params(
          options: T::Hash[Symbol, String],
        ).returns(WorkOS::Types::ListStruct)
      end
      def list_organizations(options = {})
        response = execute_request(
          request: get_request(
            path: '/organizations',
            auth: true,
            params: options,
          ),
        )

        parsed_response = JSON.parse(response.body)

        organizations = parsed_response['data'].map do |organization|
          ::WorkOS::Organization.new(organization.to_json)
        end

        WorkOS::Types::ListStruct.new(
          data: organizations,
          list_metadata: parsed_response['listMetadata'],
        )
      end

      # Get an Organization
      #
      # @param [String] id Organization unique identifier
      #
      # @example
      #   WorkOS::Portal.get_organization(id: 'org_02DRA1XNSJDZ19A31F183ECQW9')
      #   => #<WorkOS::Organization:0x00007fb6e4193d20
      #         @id="org_02DRA1XNSJDZ19A31F183ECQW9",
      #         @name="Foo Corp",
      #         @domains=
      #          [{:object=>"organization_domain",
      #            :id=>"org_domain_01E6PK9N3XMD8RHWF7S66380AR",
      #            :domain=>"foo-corp.com"}]>
      #
      # @return [WorkOS::Connection]
      sig { params(id: String).returns(WorkOS::Organization) }
      def get_organization(id:)
        request = get_request(
          auth: true,
          path: "/organizations/#{id}",
        )

        response = execute_request(request: request)

        WorkOS::Organization.new(response.body)
      end

      # Update an organization
      #
      # @param [String] organization Organization unique identifier
      # @param [Array<String>] domains List of domains that belong to the
      #  organization
      # @param [String] name A unique, descriptive name for the organization
      sig do
        params(
          organization: String,
          domains: T::Array[String],
          name: String,
        ).returns(WorkOS::Organization)
      end
      def update_organization(organization:, domains:, name:)
        request = put_request(
          auth: true,
          body: { domains: domains, name: name },
          path: "/organizations/#{organization}",
        )

        response = execute_request(request: request)
        check_and_raise_organization_error(response: response)

        WorkOS::Organization.new(response.body)
      end

      private

      sig { params(response: Net::HTTPResponse).void }
      def check_and_raise_organization_error(response:)
        begin
          body = JSON.parse(response.body)
          return unless body['message']

          message = body['message']
          request_id = response['x-request-id']
        rescue StandardError
          message = 'Something went wrong'
        end

        raise APIError.new(
          message: message,
          http_status: nil,
          request_id: request_id,
        )
      end

      sig { params(intent: String).void }
      def validate_intent(intent)
        return if GENERATE_LINK_INTENTS.include?(intent)

        raise ArgumentError, "#{intent} is not a valid value." \
        " `intent` must be in #{GENERATE_LINK_INTENTS}"
      end
    end
  end
end
