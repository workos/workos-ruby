# frozen_string_literal: true

# @oagen-ignore-file
require "aws-sdk-sts"
require_relative "aws/version"

# This gem does not depend on the WorkOS SDK gem. The parent modules are
# opened here so it loads before the SDK, after it, or without it.
module WorkOS
  module WorkloadIdentity
    # Identity token provider for AWS. It asks STS for a signed JWT that
    # identifies the workload's IAM principal (`sts:GetWebIdentityToken`,
    # IAM outbound identity federation).
    #
    # The account must have outbound identity federation enabled, and the
    # principal needs permission for `sts:GetWebIdentityToken`.
    #
    # @example
    #   provider = WorkOS::WorkloadIdentity::AWS.aws_sts("https://api.workos.com", "us-east-1")
    #   credentials = WorkOS::WorkloadIdentity::Credentials.new(identity_token_provider: provider)
    module AWS
      # Raised when STS cannot supply an identity token.
      class Error < StandardError; end

      SIGNING_ALGORITHM = "RS256"

      # Builds the STS client once, from the AWS SDK's default credential
      # chain. Fails here, not on first use, when there is no region.
      #
      # @param audience [String] The audience to request the token for. It
      #   must match the audience of the application's trust rule;
      #   conventionally `https://api.workos.com`.
      # @param region [String, nil] The AWS region whose STS endpoint to
      #   call. When nil, the region the AWS SDK resolves (`AWS_REGION`, the
      #   shared config file) is used.
      # @return [#call] A provider: each call makes one STS request and
      #   returns the JWT. It keeps no cache and does not retry.
      # @raise [Error] when no region is given and the AWS SDK finds none.
      def self.aws_sts(audience, region = nil)
        Provider.new(audience, region)
      end

      class Provider
        # `sts_client` exists for this gem's tests only: anything with a
        # `get_web_identity_token(audience:, signing_algorithm:)` method.
        def initialize(audience, region = nil, sts_client: nil)
          raise ArgumentError, "audience is required" unless audience.is_a?(String) && !audience.strip.empty?

          @audience = audience.dup.freeze
          @sts_client = sts_client || build_client(region)
        end

        # @return [String] the JWT that STS issued
        # @raise [Error]
        def call
          # No duration is sent, so STS applies its default lifetime.
          response = @sts_client.get_web_identity_token(audience: [@audience], signing_algorithm: SIGNING_ALGORITHM)
          token = response.web_identity_token
          raise Error, "sts:GetWebIdentityToken returned no token." unless token.is_a?(String) && !token.empty?

          token
        rescue Error
          raise
        rescue ::Aws::Errors::ServiceError => e
          raise Error, "sts:GetWebIdentityToken failed with #{e.code}: #{e.message}"
        rescue => e
          raise Error, "sts:GetWebIdentityToken failed: #{e.class}: #{e.message}"
        end

        def inspect
          "#<#{self.class.name} audience=#{@audience.inspect}>"
        end

        private

        # GetWebIdentityToken is not served by the global STS endpoint, so
        # the client is pinned to the regional endpoint of its region, even
        # where the environment asks for the legacy global one. The AWS SDK's
        # own retries are off (in every retry mode): a provider makes one
        # request per call, and the WorkOS SDK retries the provider.
        def build_client(region)
          options = {sts_regional_endpoints: "regional", max_attempts: 1, retry_limit: 0}
          options[:region] = region.to_s unless region.nil? || region.to_s.strip.empty?
          client = ::Aws::STS::Client.new(**options)
          if client.config.region.end_with?("-global")
            raise Error, "sts:GetWebIdentityToken needs a regional STS endpoint; #{client.config.region} is not a region."
          end

          client
        rescue ::Aws::Errors::MissingRegionError
          raise Error, "No AWS region. Pass one to aws_sts(audience, region), or set AWS_REGION."
        rescue ::Aws::Errors::InvalidRegionError => e
          raise Error, "The AWS region is not valid: #{e.message.lines.first.to_s.strip}"
        end
      end
      private_constant :Provider
    end
  end
end
