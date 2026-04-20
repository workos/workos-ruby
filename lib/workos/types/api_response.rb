# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained runtime
module WorkOS
  module Types
    # Lightweight wrapper around the raw HTTP response, exposing status,
    # headers, and request-id for observability without leaking Net::HTTP.
    ApiResponse = Data.define(:http_status, :http_headers, :request_id)
  end
end
