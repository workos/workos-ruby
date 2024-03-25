# frozen_string_literal: true

module WorkOS
  # The Factor class provides a lightweight wrapper around
  # a WorkOS DirectoryUser resource. This class is not meant to be instantiated
  # in DirectoryUser space, and is instantiated internally but exposed.
  class Factor
    include HashProvider
    attr_accessor :id, :object, :type, :sms, :totp, :updated_at, :created_at

    def initialize(json)
      hash = JSON.parse(json, symbolize_names: true)

      @id = hash[:id]
      @object = hash[:object]
      @type = hash[:type]
      @created_at = hash[:created_at]
      @updated_at = hash[:updated_at]
      @totp = hash[:totp]
      @sms = hash[:sms]
    end

    def to_json(*)
      {
        id: id,
        object: object,
        type: type,
        totp: totp,
        sms: sms,
        created_at: created_at,
        updated_at: updated_at,
      }
    end
  end
end
