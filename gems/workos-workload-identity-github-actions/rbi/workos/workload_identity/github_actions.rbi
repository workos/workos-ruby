# frozen_string_literal: true

# @oagen-ignore-file

# typed: strong

module WorkOS
  module WorkloadIdentity
    module GitHubActions
      class Error < StandardError; end

      VERSION = T.let(T.unsafe(nil), String)
      HTTP_TIMEOUT = T.let(T.unsafe(nil), Integer)
      REQUEST_URL_ENV = T.let(T.unsafe(nil), String)
      REQUEST_TOKEN_ENV = T.let(T.unsafe(nil), String)
      MISSING_ENDPOINT = T.let(T.unsafe(nil), String)
      USER_AGENT = T.let(T.unsafe(nil), String)

      sig { params(audience: String).returns(Provider) }
      def self.github_actions(audience); end

      class Provider
        sig { params(audience: String).void }
        def initialize(audience); end

        sig { returns(String) }
        def call; end
      end
      private_constant :Provider
    end
  end
end
