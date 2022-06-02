# frozen_string_literal: true
# typed: strict

require 'net/http'

module WorkOS
  # The Directory Sync module provides convenience methods for working with the
  # WorkOS Directory Sync platform. You'll need a valid API key and to have
  # created a Directory Sync connection on your WorkOS dashboard.
  #
  # @see https://docs.workos.com/directory-sync/overview
  module DirectorySync
    class << self
      extend T::Sig
      include Base
      include Client

      # Retrieve directories.
      #
      # @param [Hash] options An options hash
      # @option options [String] domain The domain of the directory to be
      #  retrieved.
      # @option options [String] search A search term for direcory names.
      # @option options [String] limit Maximum number of records to return.
      # @option options [String] order The order in which to paginate records
      # @option options [String] before Pagination cursor to receive records
      #  before a provided Directory ID.
      # @option options [String] after Pagination cursor to receive records
      #  before a provided Directory ID.
      # @option options [String] organization_id The ID for an Organization configured on WorkOS.
      #
      # @return [Hash]
      sig do
        params(
          options: T::Hash[Symbol, String],
        ).returns(WorkOS::Types::ListStruct)
      end
      def list_directories(options = {})
        response = execute_request(
          request: get_request(
            path: '/directories',
            auth: true,
            params: options,
          ),
        )

        parsed_response = JSON.parse(response.body)
        directories = parsed_response['data'].map do |directory|
          ::WorkOS::Directory.new(directory.to_json)
        end

        WorkOS::Types::ListStruct.new(
          data: directories,
          list_metadata: parsed_response['listMetadata'],
        )
      end

      # Retrieve directory.
      #
      # @param [String] id Directory unique identifier
      #
      # @example
      #   WorkOS::SSO.get_directory(id: 'directory_01FK17DWRHH7APAFXT5B52PV0W')
      #   => #<WorkOS::Directory:0x00007fb6e4193d20
      #         @id="directory_01FK17DWRHH7APAFXT5B52PV0W",
      #         @name="Foo Corp",
      #         @domain="foo-corp.com",
      #         @type="okta scim v2.0",
      #         @state="linked",
      #         @organization_id="org_01F6Q6TFP7RD2PF6J03ANNWDKV",
      #         @created_at="2021-10-27T15:55:47.856Z",
      #         @updated_at="2021-10-27T16:03:43.990Z"
      #
      # @return [WorkOS::Directory]
      sig { params(id: String).returns(WorkOS::Directory) }
      def get_directory(id:)
        request = get_request(
          auth: true,
          path: "/directories/#{id}",
        )

        response = execute_request(request: request)

        WorkOS::Directory.new(response.body)
      end

      # Retrieve directory groups.
      #
      # @param [Hash] options An options hash
      # @option options [String] directory The ID of the directory whose
      #  directory groups will be retrieved.
      # @option options [String] user The ID of the directory user whose
      #  directory groups will be retrieved.
      # @option options [String] limit Maximum number of records to return.
      # @option options [String] order The order in which to paginate records
      # @option options [String] before Pagination cursor to receive records
      #  before a provided Directory Group ID.
      # @option options [String] after Pagination cursor to receive records
      #  before a provided Directory Group ID.
      #
      # @return [WorkOS::DirectoryGroup]
      sig do
        params(
          options: T::Hash[Symbol, String],
        ).returns(WorkOS::Types::ListStruct)
      end
      def list_groups(options = {})
        response = execute_request(
          request: get_request(
            path: '/directory_groups',
            auth: true,
            params: options,
          ),
        )

        parsed_response = JSON.parse(response.body)
        groups = parsed_response['data'].map do |group|
          ::WorkOS::DirectoryGroup.new(group.to_json)
        end

        WorkOS::Types::ListStruct.new(
          data: groups,
          list_metadata: parsed_response['listMetadata'],
        )
      end

      # Retrieve directory users.
      #
      # @param [Hash] options An options hash
      # @option options [String] directory The ID of the directory whose
      #  directory users will be retrieved.
      # @option options [String] user The ID of the directory group whose
      #  directory users will be retrieved.
      # @option options [String] limit Maximum number of records to return.
      # @option options [String] order The order in which to paginate records
      # @option options [String] before Pagination cursor to receive records
      #  before a provided Directory User ID.
      # @option options [String] after Pagination cursor to receive records
      #  before a provided Directory User ID.
      #
      # @return [WorkOS::DirectoryUser]
      sig do
        params(
          options: T::Hash[Symbol, String],
        ).returns(WorkOS::Types::ListStruct)
      end
      def list_users(options = {})
        response = execute_request(
          request: get_request(
            path: '/directory_users',
            auth: true,
            params: options,
          ),
        )

        parsed_response = JSON.parse(response.body)
        users = parsed_response['data'].map do |user|
          ::WorkOS::DirectoryUser.new(user.to_json)
        end

        WorkOS::Types::ListStruct.new(
          data: users,
          list_metadata: parsed_response['listMetadata'],
        )
      end

      # Retrieve the directory group with the given ID.
      #
      # @param [String] id The ID of the directory group.
      #
      # @return WorkOS::DirectoryGroup
      sig { params(id: String).returns(WorkOS::DirectoryGroup) }
      def get_group(id)
        response = execute_request(
          request: get_request(
            path: "/directory_groups/#{id}",
            auth: true,
          ),
        )

        ::WorkOS::DirectoryGroup.new(response.body)
      end

      # Retrieve the directory user with the given ID.
      #
      # @param [String] id The ID of the directory user.
      #
      # @return WorkOS::DirectoryUser
      sig { params(id: String).returns(WorkOS::DirectoryUser) }
      def get_user(id)
        response = execute_request(
          request: get_request(
            path: "/directory_users/#{id}",
            auth: true,
          ),
        )

        ::WorkOS::DirectoryUser.new(response.body)
      end

      # Delete the directory with the given ID.
      #
      # @param [String] id The ID of the directory.
      #
      # @return Boolean
      sig { params(id: String).returns(T::Boolean) }
      def delete_directory(id)
        request = delete_request(
          auth: true,
          path: "/directories/#{id}",
        )

        response = execute_request(request: request)

        response.is_a? Net::HTTPSuccess
      end
    end
  end
end
