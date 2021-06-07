# frozen_string_literal: true
# typed: true

module WorkOS
  # The DirectoryUser class provides a lightweight wrapper around
  # a WorkOS DirectoryUser resource. This class is not meant to be instantiated
  # in DirectoryUser space, and is instantiated internally but exposed.
  class DirectoryUser
    extend T::Sig

    attr_accessor :id, :idp_id, :emails, :first_name, :last_name, :username, :state,
                  :groups, :raw_attributes

    # rubocop:disable Metrics/AbcSize
    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)

      @id = T.let(raw.id, String)
      @idp_id = T.let(raw.idp_id, String)
      @emails = T.let(raw.emails, Array)
      @first_name = raw.first_name
      @last_name = raw.last_name
      @username = raw.username
      @state = raw.state
      @groups = T.let(raw.groups, Array)
      @raw_attributes = raw.raw_attributes
    end
    # rubocop:enable Metrics/AbcSize

    def to_json(*)
      {
        id: id,
        idp_id: idp_id,
        emails: emails,
        first_name: first_name,
        last_name: last_name,
        username: username,
        state: state,
        groups: groups,
        raw_attributes: raw_attributes,
      }
    end

    private

    sig do
      params(
        json_string: String,
      ).returns(WorkOS::Types::DirectoryUserStruct)
    end
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::DirectoryUserStruct.new(
        id: hash[:id],
        idp_id: hash[:idp_id],
        emails: hash[:emails],
        first_name: hash[:first_name],
        last_name: hash[:last_name],
        username: hash[:username],
        state: hash[:state],
        groups: hash[:groups],
        raw_attributes: hash[:raw_attributes],
      )
    end
  end
end
