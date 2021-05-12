# frozen_string_literal: true
# typed: true

module WorkOS
  # The ProfileAndToken class represents a Profile and a corresponding
  # Access Token. This class is not meant to be instantiated in user space, and
  # is instantiated internally but exposed.
  class ProfileAndToken
    extend T::Sig

    attr_accessor :access_token, :profile

    sig { params(profile_and_token_json: String).void }
    def initialize(profile_and_token_json)
      json = JSON.parse(profile_and_token_json, symbolize_names: true)

      @access_token = T.let(json[:access_token], String)
      @profile = WorkOS::Profile.new(profile_and_token_json)
    end

    def to_json(*)
      {
        access_token: access_token,
        profile: profile.to_json,
      }
    end
  end
end
