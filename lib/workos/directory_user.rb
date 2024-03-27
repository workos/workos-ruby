# frozen_string_literal: true

module WorkOS
  # The DirectoryUser class provides a lightweight wrapper around
  # a WorkOS DirectoryUser resource. This class is not meant to be instantiated
  # in DirectoryUser space, and is instantiated internally but exposed.
  class DirectoryUser < DeprecatedHashWrapper
    include HashProvider

    attr_accessor :id, :idp_id, :emails, :first_name, :last_name, :job_title, :username, :state,
                  :groups, :custom_attributes, :raw_attributes, :directory_id, :organization_id,
                  :created_at, :updated_at

    # rubocop:disable Metrics/AbcSize
    def initialize(json)
      hash = JSON.parse(json, symbolize_names: true)

      @id = hash[:id]
      @directory_id = hash[:directory_id]
      @organization_id = hash[:organization_id]
      @idp_id = hash[:idp_id]
      @emails = hash[:emails]
      @first_name = hash[:first_name]
      @last_name = hash[:last_name]
      @job_title = hash[:job_title]
      @username = hash[:username]
      @state = hash[:state]
      @groups = hash[:groups]
      @custom_attributes = hash[:custom_attributes]
      @raw_attributes = hash[:raw_attributes]
      @created_at = hash[:created_at]
      @updated_at = hash[:updated_at]

      replace_without_warning(to_json)
    end
    # rubocop:enable Metrics/AbcSize

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

    def primary_email
      primary_email = (emails || []).find { |email| email[:primary] }
      return primary_email[:value] if primary_email
    end
  end
end
