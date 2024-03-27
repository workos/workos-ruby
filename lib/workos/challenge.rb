# frozen_string_literal: true

module WorkOS
  # The Challnge class provides a lightweight wrapper around
  # a WorkOS DirectoryUser resource. This class is not meant to be instantiated
  # in DirectoryUser space, and is instantiated internally but exposed.
  class Challenge
    include HashProvider

    attr_accessor :id, :object, :expires_at, :code, :authentication_factor_id, :updated_at, :created_at

    def initialize(json)
      hash = JSON.parse(json, symbolize_names: true)

      @id = hash[:id]
      @object = hash[:object]
      @expires_at = hash[:expires_at]
      @code = hash[:code]
      @authentication_factor_id = hash[:authentication_factor_id]
      @created_at = hash[:created_at]
      @updated_at = hash[:updated_at]
    end

    def to_json(*)
      {
        id: id,
        object: object,
        expires_at: expires_at,
        code: code,
        authentication_factor_id: authentication_factor_id,
        created_at: created_at,
        updated_at: updated_at,
      }
    end
  end
end
