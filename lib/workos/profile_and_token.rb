# frozen_string_literal: true

module WorkOS
  # The ProfileAndToken class represents a Profile and a corresponding
  # Access Token. This class is not meant to be instantiated in user space, and
  # is instantiated internally but exposed.
  class ProfileAndToken
    include HashProvider

    attr_accessor :access_token, :profile

    def initialize(profile_and_token_json)
      json = JSON.parse(profile_and_token_json, symbolize_names: true)

      @access_token = json[:access_token]
      @profile = WorkOS::Profile.new(json[:profile].to_json)
    end

    def to_json(*)
      {
        access_token: access_token,
        profile: profile.to_json,
      }
    end
  end
end
