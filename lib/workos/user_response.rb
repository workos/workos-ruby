# frozen_string_literal: true

module WorkOS
  # The UserResponse class represents a User as well as an corresponding
  # response data that can later be appended on.
  class UserResponse
    include HashProvider

    attr_accessor :user

    def initialize(user_response_json)
      json = JSON.parse(user_response_json, symbolize_names: true)
      @user = WorkOS::User.new(json[:user].to_json)
    end

    def to_json(*)
      {
        user: user.to_json,
      }
    end
  end
end
