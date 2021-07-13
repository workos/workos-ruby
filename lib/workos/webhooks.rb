# frozen_string_literal: true
# typed: true

require 'json'
require 'openssl'

module WorkOS
  # The Webhooks module provides convenience methods for working with the WorkOS webhooks.
  # You'll need to pull out the signature and the body from the webhook request
  # signature = request.headers['WorkOS-Signature']
  # body = request.body.read
  #
  module Webhooks
    class << self
      extend T::Sig
      include Base

      # Validate timestamp from webhook signature
      #
      # @param [String] signature The signature from the webhook sent by WorkOS.
      # @param [Integer] max_seconds_since_issued The maximum seconds allowed since webhook was issued.
      #   Default is 3 minutes (3 * 60)
      # @example
      #   WorkOS::Webhooks.validate_timestamp(
      #     signature: 't=1624472187849, v1=9c836b2369cd548c8306ca059155536bcf5d83b57b515f4c409d6900c593f39',
      #     max_seconds_since_issued: 60 * 5,
      #   )
      #
      #   => true
      #
      # @return [Boolean]
      sig do
        params(
          signature: String,
          max_seconds_since_issued: Integer,
        ).returns(T::Boolean)
      end
      def validate_timestamp(
        signature:,
        max_seconds_since_issued: 180
      )
        timestamp = parse_timestamp_from_signature(
          signature: signature,
        )

        current_time = Time.now.to_i
        timestamp_in_seconds = timestamp.to_i / 1000
        seconds_since_issued = current_time - timestamp_in_seconds

        max_seconds_since_issued > seconds_since_issued
      end

      # Validate signature hash from webhook signature
      # rubocop:disable Layout/LineLength
      #
      # @param [String] signature The signature from the webhook sent by WorkOS.
      # @param [Hash] body The body from the webhook sent by WorkOS. This is the RAW_POST_DATA of the request.
      # @example
      #   WorkOS::Webhooks.validate_signature_hash(
      #     signature: 't=1626125972272, v1=80f7ab7efadc306eb5797c588cee9410da9be4416782b497bf1e1bf4175fb928',
      #     body: "{\"data\":{\"id\":\"directory_user_01FAEAJCR3ZBZ30D8BD1924TVG\",\"state\":\"active\",\"emails\":[{\"type\":\"work\",\"value\":\"blair@foo-corp.com\",\"primary\":true}],\"idp_id\":\"00u1e8mutl6wlH3lL4x7\",\"object\":\"directory_user\",\"username\":\"blair@foo-corp.com\",\"last_name\":\"Lunceford\",\"first_name\":\"Blair\",\"directory_id\":\"directory_01F9M7F68PZP8QXP8G7X5QRHS7\",\"raw_attributes\":{\"name\":{\"givenName\":\"Blair\",\"familyName\":\"Lunceford\",\"middleName\":\"Elizabeth\",\"honorificPrefix\":\"Ms.\"},\"title\":\"Developer Success Engineer\",\"active\":true,\"emails\":[{\"type\":\"work\",\"value\":\"blair@foo-corp.com\",\"primary\":true}],\"groups\":[],\"locale\":\"en-US\",\"schemas\":[\"urn:ietf:params:scim:schemas:core:2.0:User\",\"urn:ietf:params:scim:schemas:extension:enterprise:2.0:User\"],\"userName\":\"blair@foo-corp.com\",\"addresses\":[{\"region\":\"CO\",\"primary\":true,\"locality\":\"Steamboat Springs\",\"postalCode\":\"80487\"}],\"externalId\":\"00u1e8mutl6wlH3lL4x7\",\"displayName\":\"Blair Lunceford\",\"urn:ietf:params:scim:schemas:extension:enterprise:2.0:User\":{\"manager\":{\"value\":\"2\",\"displayName\":\"Kathleen Chung\"},\"division\":\"Engineering\",\"department\":\"Customer Success\"}}},\"event\":\"dsync.user.created\"}",
      #   )
      #
      #   => true
      #
      # @return [Boolean]
      # rubocop:enable Layout/LineLength
      sig do
        params(
          signature: String,
          body: String,
          webhook_secret: String,
        ).returns(T::Boolean)
      end
      def validate_signature_hash(
        signature:,
        body:,
        webhook_secret:
      )
        timestamp = parse_timestamp_from_signature(
          signature: signature,
        )

        signature_hash = parse_signature_hash_from_signature(
          signature: signature,
        )

        event_body = JSON.parse(body)

        unhashed_string = "#{timestamp}.#{event_body.to_json}"
        digest = OpenSSL::Digest.new('sha256')
        expected_signature = OpenSSL::HMAC.hexdigest(digest, webhook_secret, unhashed_string)

        expected_signature == signature_hash
      end

      private

      sig do
        params(
          signature: String,
        ).returns(String)
      end
      def parse_timestamp_from_signature(
        signature:
      )
        split_signature = signature.split(', ')
        timestamp = split_signature[0]
        T.must(timestamp).sub('t=', '')
      end

      sig do
        params(
          signature: String,
        ).returns(String)
      end
      def parse_signature_hash_from_signature(
        signature:
      )
        split_signature = signature.split(', ')
        signature_hash = split_signature[1]
        T.must(signature_hash).sub('v1=', '')
      end
    end
  end
end
