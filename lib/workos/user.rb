# frozen_string_literal: true

module WorkOS
  # The User class provides a lightweight wrapper around a WorkOS User
  # resource. This class is not meant to be instantiated in a user space,
  # and is instantiated internally but exposed.
  class User
    include HashProvider

    attr_accessor :id, :email, :first_name, :last_name, :email_verified,
                  :profile_picture_url, :last_sign_in_at, :created_at, :updated_at

    def initialize(json)
      hash = JSON.parse(json, symbolize_names: true)

      @id = hash[:id]
      @email = hash[:email]
      @first_name = hash[:first_name]
      @last_name = hash[:last_name]
      @email_verified = hash[:email_verified]
      @profile_picture_url = hash[:profile_picture_url]
      @last_sign_in_at = hash[:last_sign_in_at]
      @email = hash[:email]
      @created_at = hash[:created_at]
      @updated_at = hash[:updated_at]
    end

    def to_json(*)
      {
        id: id,
        email: email,
        email: email,
        first_name: first_name,
        last_name: last_name,
        email_verified: email_verified,
        profile_picture_url: profile_picture_url,
        last_sign_in_at: last_sign_in_at,
        created_at: created_at,
        updated_at: updated_at,
      }
    end
  end
end
