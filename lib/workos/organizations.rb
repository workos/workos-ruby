# frozen_string_literal: true

require 'net/http'

module WorkOS
  # The Organizations module provides resource methods for working with Organizations
  module Organizations
    class << self
      include Client
      include Deprecation

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
      # @param [Array<Hash>] domain_data List of domain hashes describing an organization domain.
      # @option domain_data [String] domain The domain that belongs to the organization.
      # @option domain_data [String] state The state of the domain. "verified" or "pending"
      # @param [String] name A unique, descriptive name for the organization
      # @param [String] external_id The organization's external ID.
      # @param [String] idempotency_key An idempotency key
      # @param [Boolean, nil] allow_profiles_outside_organization Whether Connections
      #   within the Organization allow profiles that are outside of the Organization's configured User Email Domains.
      #   Deprecated: If you need to allow sign-ins from any email domain, contact suppport@workos.com.
      # @param [Array<String>] domains List of domains that belong to the organization.
      #   Deprecated: Use domain_data instead.
      def create_organization(
        domain_data: nil,
        domains: nil,
        name:,
        external_id: nil,
        allow_profiles_outside_organization: nil,
        idempotency_key: nil
      )
        body = { name: name }
        body[:domain_data] = domain_data if domain_data
        body[:external_id] = external_id if external_id

        if domains
          warn_deprecation '`domains` is deprecated. Use `domain_data` instead.'
          body[:domains] = domains
        end

        unless allow_profiles_outside_organization.nil?
          warn_deprecation '`allow_profiles_outside_organization` is deprecated. ' \
                           'If you need to allow sign-ins from any email domain, contact support@workos.com.'
          body[:allow_profiles_outside_organization] = allow_profiles_outside_organization
        end

        request = post_request(
          auth: true,
          body: body,
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
      # @param [Array<Hash>] domain_data List of domain hashes describing an organization domain.
      # @option domain_data [String] domain The domain that belongs to the organization.
      # @option domain_data [String] state The state of the domain. "verified" or "pending"
      # @param [String] stripe_customer_id The Stripe customer ID associated with this organization.
      # @param [String] name A unique, descriptive name for the organization
      # @param [String] external_id The organization's external ID.
      # @param [Boolean, nil] allow_profiles_outside_organization Whether Connections
      #   within the Organization allow profiles that are outside of the Organization's configured User Email Domains.
      #   Deprecated: If you need to allow sign-ins from any email domain, contact suppport@workos.com.
      # @param [Array<String>] domains List of domains that belong to the organization.
      #   Deprecated: Use domain_data instead.
      # rubocop:disable Metrics/ParameterLists
      def update_organization(
        organization:,
        stripe_customer_id: nil,
        domain_data: nil,
        domains: nil,
        name: nil,
        external_id: nil,
        allow_profiles_outside_organization: nil
      )
        body = {
          name: name,
          external_id: external_id,
        }
        body[:domain_data] = domain_data if domain_data
        body[:stripe_customer_id] = stripe_customer_id if stripe_customer_id

        if domains
          warn_deprecation '`domains` is deprecated. Use `domain_data` instead.'
          body[:domains] = domains
        end

        unless allow_profiles_outside_organization.nil?
          warn_deprecation '`allow_profiles_outside_organization` is deprecated. ' \
                           'If you need to allow sign-ins from any email domain, contact support@workos.com.'
          body[:allow_profiles_outside_organization] = allow_profiles_outside_organization
        end

        request = put_request(
          auth: true,
          body: body,
          path: "/organizations/#{organization}",
        )

        response = execute_request(request: request)
        check_and_raise_organization_error(response: response)

        WorkOS::Organization.new(response.body)
      end
      # rubocop:enable Metrics/ParameterLists

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

      # Retrieve a list of roles for the given organization.
      #
      # @param [String] organization_id The ID of the organization to fetch roles for.
      #
      # @example
      #   WorkOS::Organizations.list_organization_roles(organization_id: 'org_01EHZNVPK3SFK441A1RGBFSHRT')
      #   => #<WorkOS::Types::ListStruct data=[#<WorkOS::Role id="role_123" name="Admin" slug="admin"
      #                                         permissions=["admin:all"] ...>] ...>
      #
      # @return [WorkOS::Types::ListStruct] - Collection of Role objects, each including permissions array
      def list_organization_roles(organization_id:)
        response = execute_request(
          request: get_request(
            path: "/organizations/#{organization_id}/roles",
            auth: true,
          ),
        )

        parsed_response = JSON.parse(response.body)

        roles = parsed_response['data'].map do |role|
          WorkOS::Role.new(role.to_json)
        end

        WorkOS::Types::ListStruct.new(
          data: roles,
          list_metadata: {
            after: nil,
            before: nil,
          },
        )
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
