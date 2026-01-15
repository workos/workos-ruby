# frozen_string_literal: true

module WorkOS
  module UserManagement
    # The Session class provides a lightweight wrapper around
    # a WorkOS Session resource. This class is not meant to be instantiated
    # in user space, and is instantiated internally but exposed.
    class Session
      include HashProvider
      attr_accessor :id, :object, :user_id, :organization_id, :status, :auth_method,
                    :ip_address, :user_agent, :expires_at, :ended_at, :created_at, :updated_at

      # rubocop:disable Metrics/AbcSize
      def initialize(json)
        hash = JSON.parse(json, symbolize_names: true)

        @id = hash[:id]
        @object = hash[:object]
        @user_id = hash[:user_id]
        @organization_id = hash[:organization_id]
        @status = hash[:status]
        @auth_method = hash[:auth_method]
        @ip_address = hash[:ip_address]
        @user_agent = hash[:user_agent]
        @expires_at = hash[:expires_at]
        @ended_at = hash[:ended_at]
        @created_at = hash[:created_at]
        @updated_at = hash[:updated_at]
      end
      # rubocop:enable Metrics/AbcSize

      def to_json(*)
        {
          id: id,
          object: object,
          user_id: user_id,
          organization_id: organization_id,
          status: status,
          auth_method: auth_method,
          ip_address: ip_address,
          user_agent: user_agent,
          expires_at: expires_at,
          ended_at: ended_at,
          created_at: created_at,
          updated_at: updated_at,
        }
      end

      # Revoke this session
      #
      # @return [Bool] - returns `true` if successful
      def revoke
        WorkOS::UserManagement.revoke_session(session_id: id)
      end
    end
  end
end
