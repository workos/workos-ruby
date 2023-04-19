# frozen_string_literal: true
# typed: true

module WorkOS
  # The DirectoryUser class provides a lightweight wrapper around
  # a WorkOS DirectoryUser resource. This class is not meant to be instantiated
  # in DirectoryUser space, and is instantiated internally but exposed.
  class DirectoryUser < DeprecatedHashWrapper
    include HashProvider
    extend T::Sig

    attr_accessor :id, :idp_id, :emails, :first_name, :last_name, :job_title, :username, :state,
                  :groups, :custom_attributes, :raw_attributes, :directory_id, :organization_id,
                  :created_at, :updated_at

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)

      @id = T.let(raw.id, String)
      @directory_id = T.let(raw.directory_id, String)
      @organization_id = raw.organization_id
      @idp_id = T.let(raw.idp_id, String)
      @emails = T.let(raw.emails, Array)
      @first_name = raw.first_name
      @last_name = raw.last_name
      @job_title = raw.job_title
      @username = raw.username
      @state = raw.state
      @groups = T.let(raw.groups, Array)
      @custom_attributes = raw.custom_attributes
      @raw_attributes = raw.raw_attributes
      @created_at = T.let(raw.created_at, String)
      @updated_at = T.let(raw.updated_at, String)

      replace_without_warning(to_json)
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def to_json(*)
      {
        id: id,
        directory_id: directory_id,
        organization_id: organization_id,
        idp_id: idp_id,
        emails: emails,
        first_name: first_name,
        last_name: last_name,
        job_title: job_title,
        username: username,
        state: state,
        groups: groups,
        custom_attributes: custom_attributes,
        raw_attributes: raw_attributes,
        created_at: created_at,
        updated_at: updated_at,
      }
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def primary_email
      primary_email = (emails || []).find { |email| email[:primary] }
      return primary_email[:value] if primary_email
    end

    private

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    sig do
      params(
        json_string: String,
      ).returns(WorkOS::Types::DirectoryUserStruct)
    end
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::DirectoryUserStruct.new(
        id: hash[:id],
        directory_id: hash[:directory_id],
        organization_id: hash[:organization_id],
        idp_id: hash[:idp_id],
        emails: hash[:emails],
        first_name: hash[:first_name],
        last_name: hash[:last_name],
        job_title: hash[:job_title],
        username: hash[:username],
        state: hash[:state],
        groups: hash[:groups],
        custom_attributes: hash[:custom_attributes],
        raw_attributes: hash[:raw_attributes],
        created_at: hash[:created_at],
        updated_at: hash[:updated_at],
      )
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  end
end
