# frozen_string_literal: true

module WorkOS
  # The Invitation class provides a lightweight wrapper around a WorkOS Invitation
  # resource. This class is not meant to be instantiated in a user space,
  # and is instantiated internally but exposed.
  class Invitation
    include HashProvider

    attr_accessor :id, :email, :state, :accepted_at, :revoked_at,
                  :expires_at, :token, :organization_id, :created_at, :updated_at

    def initialize(json)
      hash = JSON.parse(json, symbolize_names: true)

      @id = hash[:id]
      @email = hash[:email]
      @state = hash[:state]
      @token = hash[:token]
      @organization_id = hash[:organization_id]
      @accepted_at = hash[:accepted_at]
      @revoked_at = hash[:revoked_at]
      @expires_at = hash[:expires_at]
      @created_at = hash[:created_at]
      @updated_at = hash[:updated_at]
    end

    def to_json(*)
      {
        id: id,
        email: email,
        state: state,
        token: token,
        organization_id: organization_id,
        accepted_at: accepted_at,
        revoked_at: revoked_at,
        expires_at: expires_at,
        created_at: created_at,
        updated_at: updated_at,
      }
    end
  end
end
