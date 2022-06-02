# frozen_string_literal: true
# typed: true

module WorkOS
  # The Profile class provides a lighweight wrapper around
  # a normalized response from the various IDPs WorkOS
  # supports as part of the SSO integration. This class
  # is not meant to be instantiated in user space, and
  # is instantiated internally but exposed.
  class Profile
    include HashProvider
    extend T::Sig

    sig { returns(String) }
    attr_accessor :id, :email, :first_name, :last_name, :organization_id,
                  :connection_id, :connection_type, :idp_id, :raw_attributes

    # rubocop:disable Metrics/AbcSize
    sig { params(profile_json: String).void }
    def initialize(profile_json)
      raw = parse_json(profile_json)

      @id = T.let(raw.id, String)
      @email = T.let(raw.email, String)
      @first_name = raw.first_name
      @last_name = raw.last_name
      @organization_id = raw.organization_id
      @connection_id = T.let(raw.connection_id, String)
      @connection_type = T.let(raw.connection_type, String)
      @idp_id = raw.idp_id
      @raw_attributes = raw.raw_attributes
    end
    # rubocop:enable Metrics/AbcSize

    sig { returns(String) }
    def full_name
      [first_name, last_name].compact.join(' ')
    end

    def to_json(*)
      {
        id: id,
        email: email,
        first_name: first_name,
        last_name: last_name,
        organization_id: organization_id,
        connection_id: connection_id,
        connection_type: connection_type,
        idp_id: idp_id,
        raw_attributes: raw_attributes,
      }
    end

    private

    sig { params(json_string: String).returns(WorkOS::Types::ProfileStruct) }
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::ProfileStruct.new(
        id: hash[:id],
        email: hash[:email],
        first_name: hash[:first_name],
        last_name: hash[:last_name],
        organization_id: hash[:organization_id],
        connection_id: hash[:connection_id],
        connection_type: hash[:connection_type],
        idp_id: hash[:idp_id],
        raw_attributes: hash[:raw_attributes],
      )
    end
  end
end
