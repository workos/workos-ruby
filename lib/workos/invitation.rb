# frozen_string_literal: true
# typed: true

module WorkOS
  # The Invitation class provide a lightweight wrapper around a WorkOS Invitation
  # resource. This class is not meant to be instantiated in a user space,
  # and is instantiated internally but exposed.
  class Invitation
    include HashProvider
    extend T::Sig

    attr_accessor :id, :email, :state, :accepted_at, :revoked_at,
                  :expires_at, :token, :organization_id, :created_at, :updated_at

    # rubocop:disable Metrics/AbcSize
    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)

      @id = T.let(raw.id, String)
      @email = T.let(raw.email, String)
      @state = T.let(raw.state, String)
      @token = T.let(raw.token, String)
      @organization_id = T.let(raw.organization_id, T.nilable(String))
      @accepted_at = T.let(raw.accepted_at, T.nilable(String))
      @revoked_at = T.let(raw.revoked_at, T.nilable(String))
      @expires_at = T.let(raw.expires_at, String)
      @created_at = T.let(raw.created_at, String)
      @updated_at = T.let(raw.updated_at, String)
    end
    # rubocop:enable Metrics/AbcSize

    def to_json(*)
      {
        id: id,
        email: email,
        state: state,
        token: token,
        accepted_at: accepted_at,
        revoked_at: revoked_at,
        expires_at: expires_at,
        created_at: created_at,
        updated_at: updated_at,
      }
    end

    private

    sig { params(json_string: String).returns(WorkOS::Types::InvitationStruct) }
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::InvitationStruct.new(
        id: hash[:id],
        email: hash[:email],
        state: hash[:state],
        token: hash[:token],
        accepted_at: hash[:accepted_at],
        revoked_at: hash[:revoked_at],
        expires_at: hash[:expires_at],
        created_at: hash[:created_at],
        updated_at: hash[:updated_at],
      )
    end
  end
end
