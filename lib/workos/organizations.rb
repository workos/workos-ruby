# frozen_string_literal: true

require 'net/http'

module WorkOS
  # The Organizations module provides resource methods for working with Organizations
  module Organizations
    class << self
      include Client

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
      # @param [String] order The order in which to paginate records
      #  of listed Organizations that are returned.
      def list_organizations(options = {})
        options[:order] ||= 'desc'
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
      # @return [WorkOS::Organization]
      def get_organization(id:)
        request = get_request(
          auth: true,
          path: "/organizations/#{id}",
        )

        response = execute_request(request: request)

        WorkOS::Organization.new(response.body)
      end

      # Create an organization
      #
      # @param [Array<String>] domains List of domains that belong to the
      #  organization
      # @param [String] name A unique, descriptive name for the organization
      # @param [Boolean, nil] allow_profiles_outside_organization Whether Connections
      #  within the Organization allow profiles that are outside of the Organization's configured User Email Domains.
      # @param [String] idempotency_key An idempotency key
      def create_organization(domains:, name:, allow_profiles_outside_organization: nil, idempotency_key: nil)
        request = post_request(
          auth: true,
          body: {
            domains: domains,
            name: name,
            allow_profiles_outside_organization: allow_profiles_outside_organization,
          },
          path: '/organizations',
          idempotency_key: idempotency_key,
        )

        response = execute_request(request: request)
        check_and_raise_organization_error(response: response)

        WorkOS::Organization.new(response.body)
      end

      # Update an organization
      #
      # @param [String] organization Organization unique identifier
      # @param [Array<String>] domains List of domains that belong to the
      #  organization
      # @param [String] name A unique, descriptive name for the organization
      # @param [Boolean, nil] allow_profiles_outside_organization Whether Connections
      #  within the Organization allow profiles that are outside of the Organization's configured User Email Domains.
      def update_organization(organization:, domains:, name:, allow_profiles_outside_organization: nil)
        request = put_request(
          auth: true,
          body: {
            domains: domains,
            name: name,
            allow_profiles_outside_organization: allow_profiles_outside_organization,
          },
          path: "/organizations/#{organization}",
        )

        response = execute_request(request: request)
        check_and_raise_organization_error(response: response)

        WorkOS::Organization.new(response.body)
      end

      # Delete an Organization
      #
      # @param [String] id Organization unique identifier
      #
      # @example
      #   WorkOS::SSO.delete_organization(id: 'org_01EHZNVPK3SFK441A1RGBFSHRT')
      #   => true
      #
      # @return [Bool] - returns `true` if successful
      def delete_organization(id:)
        request = delete_request(
          auth: true,
          path: "/organizations/#{id}",
        )

        response = execute_request(request: request)

        response.is_a? Net::HTTPSuccess
      end

      private

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
    end
  end
end
