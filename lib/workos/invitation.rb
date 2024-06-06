# frozen_string_literal: true

module WorkOS
  # The Invitation class provides a lightweight wrapper around a WorkOS Invitation
  # resource. This class is not meant to be instantiated in a user space,
  # and is instantiated internally but exposed.
  class Invitation
    include HashProvider

    attr_accessor :id, :email, :state, :accepted_at, :revoked_at, :accept_invitation_url,
                  :expires_at, :token, :organization_id, :inviter_user_id, :created_at, :updated_at

    # rubocop:disable Metrics/AbcSize
    def initialize(json)
      hash = JSON.parse(json, symbolize_names: true)

      @id = hash[:id]
      @email = hash[:email]
      @state = hash[:state]
      @token = hash[:token]
      @accept_invitation_url = hash[:accept_invitation_url]
      @organization_id = hash[:organization_id]
      @inviter_user_id = hash[:inviter_user_id]
      @accepted_at = hash[:accepted_at]
      @revoked_at = hash[:revoked_at]
      @expires_at = hash[:expires_at]
      @created_at = hash[:created_at]
      @updated_at = hash[:updated_at]
    end
    # rubocop:enable Metrics/AbcSize

    def to_json(*)
      {
        id: id,
        email: email,
        state: state,
        token: token,
        accept_invitation_url: accept_invitation_url,
        organization_id: organization_id,
        inviter_user_id: inviter_user_id,
        accepted_at: accepted_at,
        revoked_at: revoked_at,
        expires_at: expires_at,
        created_at: created_at,
        updated_at: updated_at,
      }
    end
  end
end
