# frozen_string_literal: true
# typed: true

module WorkOS
  # The Webhook class provides a lightweight wrapper around
  # a WorkOS Webhook resource. This class is not meant to be instantiated
  # in user space, and is instantiated internally but exposed.
  class Webhook
    include HashProvider
    extend T::Sig

    attr_accessor :id, :event, :data, :created_at

    sig { params(json: String).void }
    def initialize(json)
      raw = parse_json(json)

      @id = T.let(raw.id, String)
      @event = T.let(raw.event, String)
      @data = raw.data
      @created_at = T.let(raw.created_at, String)
    end

    def to_json(*)
      {
        id: id,
        event: event,
        data: data,
        created_at: created_at,
      }
    end

    private

    sig do
      params(
        json_string: String,
      ).returns(WorkOS::Types::WebhookStruct)
    end
    def parse_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)

      WorkOS::Types::WebhookStruct.new(
        id: hash[:id],
        event: hash[:event],
        data: hash[:data],
        created_at: hash[:created_at],
      )
    end
  end
end
