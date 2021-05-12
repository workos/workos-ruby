# frozen_string_literal: true
# typed: true

module WorkOS
  # The ProfileAndToken class represents a Profile and a corresponding
  # Access Token. This class is not meant to be instantiated in user space, and
  # is instantiated internally but exposed.
  class ProfileAndToken
    extend T::Sig

    attr_accessor :access_token, :profile

    sig { params(profile_and_token: String).void }
    def initialize(profile_and_token)
      raw = parse_json(profile_and_token)

      @access_token = T.let(raw.access_token, String)
      @profile = WorkOS::Profile.new(profile_and_token)
    end

    def to_json(*)
      {
        access_token: access_token,
        profile: profile.to_json,
      }
    end

    private

    sig { params(json_string: String).returns(WorkOS::Types::ProfileAndTokenStruct) }
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::ProfileAndTokenStruct.new(
        access_token: hash[:access_token],
        profile: hash[:profile],
      )
    end
  end
end
