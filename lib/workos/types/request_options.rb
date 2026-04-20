# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained runtime

module WorkOS
  module Types
    # Documentation-only class describing the per-request override keys
    # accepted by every generated service method via the `request_options`
    # keyword argument.
    #
    # @!attribute [r] api_key
    #   @return [String, nil] Override the client-level API key for this request.
    #
    # @!attribute [r] timeout
    #   @return [Integer, nil] Override the HTTP timeout (seconds) for this request.
    #
    # @!attribute [r] base_url
    #   @return [String, nil] Override the base URL for this request.
    #
    # @!attribute [r] max_retries
    #   @return [Integer, nil] Override the maximum number of retries for this request.
    #
    # @!attribute [r] idempotency_key
    #   @return [String, nil] Set a custom Idempotency-Key header for this request.
    #
    # @!attribute [r] extra_headers
    #   @return [Hash{String => String}, nil] Additional HTTP headers to send with this request.
    class RequestOptions
      # This class is never instantiated — it exists solely for YARD
      # documentation. Service methods accept a plain Hash.
    end
  end
end
