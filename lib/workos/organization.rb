# frozen_string_literal: true

module WorkOS
  # The Organization class provides a lightweight wrapper around
  # a WorkOS Organization resource. This class is not meant to be instantiated
  # in user space, and is instantiated internally but exposed.
  class Organization
    include HashProvider

    attr_accessor(
      :id,
      :domains,
      :stripe_customer_id,
      :name,
      :external_id,
      :allow_profiles_outside_organization,
      :created_at,
      :updated_at,
    )

    def initialize(json)
      hash = JSON.parse(json, symbolize_names: true)

      @id = hash[:id]
      @name = hash[:name]
      @external_id = hash[:external_id]
      @allow_profiles_outside_organization = hash[:allow_profiles_outside_organization]
      @domains = hash[:domains]
      @stripe_customer_id = hash[:stripe_customer_id]
      @created_at = hash[:created_at]
      @updated_at = hash[:updated_at]
    end

    def to_json(*)
      {
        id: id,
        name: name,
        external_id: external_id,
        allow_profiles_outside_organization: allow_profiles_outside_organization,
        domains: domains,
        stripe_customer_id: stripe_customer_id,
        created_at: created_at,
        updated_at: updated_at,
      }
    end
  end
end
