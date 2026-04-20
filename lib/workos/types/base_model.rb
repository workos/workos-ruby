# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained runtime
require "json"

module WorkOS
  module Types
    # Shared base class for all generated model classes.
    #
    # Provides:
    # - HashProvider mixin for to_h / to_json / inspect
    # - normalize(input) for JSON-vs-hash / string-vs-symbol normalization
    #
    # Subclasses declare HASH_ATTRS for serialization and implement their
    # own initialize(json) using normalize to parse input.
    # Lightweight wrapper around the raw HTTP response, exposing status,
    # headers, and request-id for observability without leaking Net::HTTP.
    ApiResponse = Data.define(:http_status, :http_headers, :request_id)

    class BaseModel
      include HashProvider

      # The raw HTTP response metadata for this object, if available.
      # Populated automatically by service methods that return models.
      # @return [WorkOS::Types::ApiResponse, nil]
      attr_accessor :last_response

      # Normalize an input value (JSON string or Hash) into a Hash with
      # symbolized keys. Safe for already-symbolized hashes (no-op).
      #
      # @param json [String, Hash] JSON string or hash to normalize.
      # @return [Hash{Symbol => Object}]
      def self.normalize(json)
        hash = json.is_a?(Hash) ? json : JSON.parse(json, symbolize_names: true)
        hash.transform_keys(&:to_sym)
      end
    end
  end
end
