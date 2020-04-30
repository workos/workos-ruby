# frozen_string_literal: true
# typed: true

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
      #
      # @return [Hash]
      sig do
        params(
          options: T::Hash[Symbol, String],
        ).returns(T::Array[T::Hash[String, T.nilable(String)]])
      end
      def list_directories(options = {})
        response = execute_request(
          request: get_request(
            path: '/directories',
            auth: true,
            params: options,
          ),
        )

        JSON.parse(response.body)['data']
      end

      # Retrieve directory groups.
      #
      # @param [Hash] options An options hash
      # @option options [String] directory The ID of the directory whose
      #  directory groups will be retrieved.
      # @option options [String] user The ID of the directory user whose
      #  directory groups will be retrieved.
      #
      # @return [Hash]
      sig do
        params(
          options: T::Hash[Symbol, String],
        ).returns(T::Array[T::Hash[String, T.nilable(String)]])
      end
      def list_groups(options = {})
        response = execute_request(
          request: get_request(
            path: '/directory_groups',
            auth: true,
            params: options,
          ),
        )

        JSON.parse(response.body)['data']
      end

      # Retrieve directory users.
      #
      # @param [Hash] options An options hash
      # @option options [String] directory The ID of the directory whose
      #  directory users will be retrieved.
      # @option options [String] user The ID of the directory group whose
      #  directory users will be retrieved.
      #
      # @return [Hash]
      sig do
        params(
          options: T::Hash[Symbol, String],
        ).returns(T::Array[T::Hash[String, T.untyped]])
      end
      def list_users(options = {})
        response = execute_request(
          request: get_request(
            path: '/directory_users',
            auth: true,
            params: options,
          ),
        )

        JSON.parse(response.body)['data']
      end

      # Retrieve the directory group with the given ID.
      #
      # @param [String] id The ID of the directory group.
      #
      # @return Hash
      sig { params(id: String).returns(T::Hash[String, T.untyped]) }
      def get_group(id)
        response = execute_request(
          request: get_request(
            path: "/directory_groups/#{id}",
            auth: true,
          ),
        )

        JSON.parse(response.body)
      end

      # Retrieve the directory user with the given ID.
      #
      # @param [String] id The ID of the directory user.
      #
      # @return Hash
      sig { params(id: String).returns(T::Hash[String, T.untyped]) }
      def get_user(id)
        response = execute_request(
          request: get_request(
            path: "/directory_users/#{id}",
            auth: true,
          ),
        )

        JSON.parse(response.body)
      end
    end
  end
end
