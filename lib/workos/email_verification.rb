# frozen_string_literal: true

module WorkOS
  # The EmailVerification class provides a lightweight wrapper around a WorkOS email
  # verification resource. This class is not meant to be instantiated in a user space,
  # and is instantiated internally but exposed.
  class EmailVerification
    include HashProvider

    attr_accessor :id, :user_id, :email,
                  :expires_at, :code, :created_at, :updated_at

    def initialize(json)
      hash = JSON.parse(json, symbolize_names: true)

      @id = hash[:id]
      @user_id = hash[:user_id]
      @email = hash[:email]
      @code = hash[:code]
      @expires_at = hash[:expires_at]
      @created_at = hash[:created_at]
      @updated_at = hash[:updated_at]
    end

    def to_json(*)
      {
        id: id,
        user_id: user_id,
        email: email,
        code: code,
        expires_at: expires_at,
        created_at: created_at,
        updated_at: updated_at,
      }
    end
  end
end
