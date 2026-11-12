# frozen_string_literal: true

# @oagen-ignore-file

# typed: strong

module WorkOS
  module WorkloadIdentity
    module AWS
      class Error < StandardError; end

      VERSION = T.let(T.unsafe(nil), String)
      SIGNING_ALGORITHM = T.let(T.unsafe(nil), String)

      sig { params(audience: String, region: T.nilable(String)).returns(Provider) }
      def self.aws_sts(audience, region = nil); end

      class Provider
        sig { params(audience: String, region: T.nilable(String), sts_client: T.untyped).void }
        def initialize(audience, region = nil, sts_client: nil); end

        sig { returns(String) }
        def call; end

        sig { returns(String) }
        def inspect; end
      end
      private_constant :Provider
    end
  end
end
