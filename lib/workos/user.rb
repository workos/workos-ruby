# frozen_string_literal: true
# typed: true

module WorkOS
  # The User class provides a lightweight wrapper around
  # a WorkOS User resource. This class is not meant to be instantiated
  # in user space, and is instantiated internally but exposed.
  class User
    extend T::Sig

    attr_accessor :id, :emails, :first_name, :last_name, :username, :state,
                  :raw_attributes

    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)

      @id = T.let(raw.id, String)
      @emails = T.let(raw.emails, Array)
      @first_name = raw.first_name
      @last_name = raw.last_name
      @username = raw.username
      @state = raw.state
      @raw_attributes = raw.raw_attributes
    end

    def to_json(*)
      {
        id: id,
        emails: emails,
        first_name: first_name,
        last_name: last_name,
        username: username,
        state: state,
        raw_attributes: raw_attributes,
      }
    end

    private

    sig do
      params(
        json_string: String,
      ).returns(WorkOS::Types::UserStruct)
    end
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::UserStruct.new(
        id: hash[:id],
        emails: hash[:emails],
        first_name: hash[:first_name],
        last_name: hash[:last_name],
        username: hash[:username],
        state: hash[:state],
        raw_attributes: hash[:raw_attributes],
      )
    end
  end
end
