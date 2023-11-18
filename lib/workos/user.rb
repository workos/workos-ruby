# frozen_string_literal: true
# typed: true

module WorkOS
  # The User class provide a lightweight wrapper around a WorkOS User
  # resource. This class is not meant to be instantiated in a user space,
  # and is instantiated internally but exposed.
  class User
    include HashProvider
    extend T::Sig

    attr_accessor :id, :object, :email, :first_name, :last_name, :email_verified,
                  :created_at, :updated_at

    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)

      @id = T.let(raw.id, String)
      @object = raw.object
      @email = T.let(raw.email, String)
      @first_name = raw.first_name
      @last_name = raw.last_name
      @email_verified = raw.email_verified
      @created_at = T.let(raw.created_at, String)
      @updated_at = T.let(raw.updated_at, String)
    end

    def to_json(*)
      {
        id: id,
        object: object,
        email: email,
        first_name: first_name,
        last_name: last_name,
        email_verified: email_verified,
        created_at: created_at,
        updated_at: updated_at,
      }
    end

    private

    sig { params(json_string: String).returns(WorkOS::Types::UserStruct) }
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::UserStruct.new(
        id: hash[:id],
        object: hash[:object],
        email: hash[:email],
        first_name: hash[:first_name],
        last_name: hash[:last_name],
        email_verified: hash[:email_verified],
        created_at: hash[:created_at],
        updated_at: hash[:updated_at],
      )
    end
  end
end
