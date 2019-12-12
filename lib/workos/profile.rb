# typed: true
# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize

require 'json'

module WorkOS
  # The Profile class provides a lighweight wrapper around
  # a normalized response from the various IDPs WorkOS
  # supports as part of the SSO integration
  class Profile
    extend T::Sig

    sig { returns(String) }
    attr_accessor :id, :email, :first_name, :last_name,
                  :connection_type, :idp_id

    sig { params(profile_json: String).void }
    def initialize(profile_json)
      raw = WorkOS::Profile.parse_json(profile_json)

      @id              = T.let(raw.id, String)
      @email           = T.let(raw.email, String)
      @first_name      = T.let(raw.first_name, String)
      @last_name       = T.let(raw.last_name, String)
      @connection_type = T.let(raw.connection_type, String)
      @idp_id          = T.let(raw.idp_id, String)
    end

    sig { returns(String) }
    def full_name
      [first_name, last_name].compact.join(' ')
    end

    class << self
      extend T::Sig

      sig { params(json_string: String).returns(WorkOS::Types::ProfileStruct) }

      def parse_json(json_string)
        hash = JSON.parse(json_string, symbolize_names: true)

        WorkOS::Types::ProfileStruct.new(
          id: hash[:profile][:id],
          email: hash[:profile][:email],
          first_name: hash[:profile][:first_name],
          last_name: hash[:profile][:last_name],
          connection_type: hash[:profile][:connection_type],
          idp_id: hash[:profile][:idp_id],
        )
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize
