# frozen_string_literal: true

module WorkOS
  # The PasswordReset class provides a lightweight wrapper around a WorkOS password
  # reset resource. This class is not meant to be instantiated in a user space,
  # and is instantiated internally but exposed.
  class PasswordReset
    include HashProvider

    attr_accessor :id, :user_id, :email, :password_reset_token,
                  :password_reset_url, :expires_at, :created_at

    def initialize(json)
      hash = JSON.parse(json, symbolize_names: true)

      @id = hash[:id]
      @user_id = hash[:user_id]
      @email = hash[:email]
      @password_reset_token = hash[:password_reset_token]
      @password_reset_url = hash[:password_reset_url]
      @expires_at = hash[:expires_at]
      @created_at = hash[:created_at]
    end

    def to_json(*)
      {
        id: id,
        user_id: user_id,
        email: email,
        password_reset_token: password_reset_token,
        password_reset_url: password_reset_url,
        expires_at: expires_at,
        created_at: created_at,
      }
    end
  end
end
