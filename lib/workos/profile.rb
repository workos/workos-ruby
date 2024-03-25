# frozen_string_literal: true

module WorkOS
  # The Profile class provides a lighweight wrapper around
  # a normalized response from the various IDPs WorkOS
  # supports as part of the SSO integration. This class
  # is not meant to be instantiated in user space, and
  # is instantiated internally but exposed.
  class Profile
    include HashProvider

    attr_accessor :id, :email, :first_name, :last_name, :groups, :organization_id,
                  :connection_id, :connection_type, :idp_id, :raw_attributes

    def initialize(profile_json)
      hash = JSON.parse(profile_json, symbolize_names: true)

      @id = hash[:id]
      @email = hash[:email]
      @first_name = hash[:first_name]
      @last_name = hash[:last_name]
      @groups = hash[:groups]
      @organization_id = hash[:organization_id]
      @connection_id = hash[:connection_id]
      @connection_type = hash[:connection_type]
      @idp_id = hash[:idp_id]
      @raw_attributes = hash[:raw_attributes]
    end

    def full_name
      [first_name, last_name].compact.join(' ')
    end

    def to_json(*)
      {
        id: id,
        email: email,
        first_name: first_name,
        last_name: last_name,
        groups: groups,
        organization_id: organization_id,
        connection_id: connection_id,
        connection_type: connection_type,
        idp_id: idp_id,
        raw_attributes: raw_attributes,
      }
    end
  end
end
