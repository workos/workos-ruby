# frozen_string_literal: true
# typed: true

require 'net/http'
require 'uri'

module WorkOS
  # The UserManagement module provides convenience methods for working with the
  # WorkOS User platform. You'll need a valid API key.
  module UserManagement
    class << self
      extend T::Sig
      include Client

      sig do
        params(id: String).returns(WorkOS::User)
      end
      def get_user(id:)
        response = execute_request(
          request: get_request(
            path: "/users/#{id}",
            auth: true,
          ),
        )

        WorkOS::User.new(response.body)
      end

      # Retrieve a list of users.
      #
      # @param [Hash] options
      # @option options [String] type Filter Users by their type.
      # @option options [String] email Filter Users by their email.
      # @option options [String] organization Filter Users by the organization
      #  they are members of.
      # @option options [String] limit Maximum number of records to return.
      # @option options [String] order The order in which to paginate records
      # @option options [String] before Pagination cursor to receive records
      #  before a provided User ID.
      # @option options [String] after Pagination cursor to receive records
      #  before a provided User ID.
      #
      # @return [WorkOS::User]
      sig do
        params(
          options: T::Hash[Symbol, String],
        ).returns(WorkOS::Types::ListStruct)
      end
      def list_users(options = {})
        response = execute_request(
          request: get_request(
            path: '/users',
            auth: true,
            params: options,
          ),
        )

        parsed_response = JSON.parse(response.body)

        users = parsed_response['data'].map do |user|
          ::WorkOS::User.new(user.to_json)
        end

        WorkOS::Types::ListStruct.new(
          data: users,
          list_metadata: parsed_response['list_metadata'],
        )
      end

      # Removes an unmanaged User from the given Organization.
      #
      # @param [String] id The unique ID of the User.
      # @param [String] organization_id Unique identifier of the Organization.
      #
      # @return WorkOS::User
      sig do
        params(
          id: String,
          organization_id: String,
        ).returns(WorkOS::User)
      end
      def remove_user_from_organization(id:, organization_id:)
        response = execute_request(
          request: delete_request(
            path: "/users/#{id}/organizations/#{organization_id}",
            auth: true,
          ),
        )

        WorkOS::User.new(response.body)
      end
    end
  end
end
