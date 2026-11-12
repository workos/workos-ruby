# frozen_string_literal: true

# @oagen-ignore-file

# typed: strong

module WorkOS
  module WorkloadIdentity
    module GCP
      class Error < StandardError; end

      VERSION = T.let(T.unsafe(nil), String)
      HTTP_TIMEOUT = T.let(T.unsafe(nil), Integer)
      METADATA_BASE_URL = T.let(T.unsafe(nil), String)
      IDENTITY_PATH = T.let(T.unsafe(nil), String)
      USER_AGENT = T.let(T.unsafe(nil), String)

      sig { params(audience: String).returns(Provider) }
      def self.gcp_metadata(audience); end

      class Provider
        sig { params(audience: String, base_url: String).void }
        def initialize(audience, base_url: T.unsafe(nil)); end

        sig { returns(String) }
        def call; end
      end
      private_constant :Provider
    end
  end
end
