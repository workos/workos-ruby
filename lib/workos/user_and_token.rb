# frozen_string_literal: true

module WorkOS
  # The UserAndToken class represents a User and a corresponding Token. This
  # class is not meant to be instantiated in user space, and is instantiated
  # internally but exposed.
  class UserAndToken
    include HashProvider

    attr_accessor :token, :user

    def initialize(user_and_token_json)
      json = JSON.parse(user_and_token_json, symbolize_names: true)

      @token = json[:token]
      @user = WorkOS::User.new(json[:user].to_json)
    end

    def to_json(*)
      {
        token: token,
        user: user.to_json,
      }
    end
  end
end
