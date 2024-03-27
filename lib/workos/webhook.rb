# frozen_string_literal: true

module WorkOS
  # The Webhook class provides a lightweight wrapper around
  # a WorkOS Webhook resource. This class is not meant to be instantiated
  # in user space, and is instantiated internally but exposed.
  class Webhook
    include HashProvider

    attr_accessor :id, :event, :data, :created_at

    def initialize(json)
      hash = JSON.parse(json, symbolize_names: true)

      @id = hash[:id]
      @event = hash[:event]
      @data = hash[:data]
      @created_at = hash[:created_at]
    end

    def to_json(*)
      {
        id: id,
        event: event,
        data: data,
        created_at: created_at,
      }
    end
  end
end
