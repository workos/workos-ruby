# frozen_string_literal: true
# typed: true

require 'openssl'

module WorkOS
  # The Webhooks module provides convenience methods for working with the WorkOS webhooks.
  # You'll need to extract the signature header and payload from the webhook request
  # sig_header = request.headers['WorkOS-Signature']
  # payload = request.body.read
  #
  # The secret is the Webhook Secret from your WorkOS Dashboard
  # The tolerance is for the timestamp validation
  #
  module Webhooks
    class << self
      extend T::Sig

      DEFAULT_TOLERANCE = 180

      # Initializes an Event object from a JSON payload
      # rubocop:disable Layout/LineLength
      #
      # @param [String] payload The payload from the webhook sent by WorkOS. This is the RAW_POST_DATA of the request.
      # @param [String] sig_header The signature from the webhook sent by WorkOS.
      # @param [String] secret The webhook secret from the WorkOS dashboard.
      # @param [Integer] tolerance The time tolerance in seconds for the webhook.
      #
      # @example
      #   WorkOS::Webhooks.construct_event(
      #     payload: "{"id": "wh_123","data":{"id":"directory_user_01FAEAJCR3ZBZ30D8BD1924TVG","state":"active","emails":[{"type":"work","value":"blair@foo-corp.com","primary":true}],"idp_id":"00u1e8mutl6wlH3lL4x7","object":"directory_user","username":"blair@foo-corp.com","last_name":"Lunceford","first_name":"Blair","directory_id":"directory_01F9M7F68PZP8QXP8G7X5QRHS7","raw_attributes":{"name":{"givenName":"Blair","familyName":"Lunceford","middleName":"Elizabeth","honorificPrefix":"Ms."},"title":"Developer Success Engineer","active":true,"emails":[{"type":"work","value":"blair@foo-corp.com","primary":true}],"groups":[],"locale":"en-US","schemas":["urn:ietf:params:scim:schemas:core:2.0:User","urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"],"userName":"blair@foo-corp.com","addresses":[{"region":"CO","primary":true,"locality":"Steamboat Springs","postalCode":"80487"}],"externalId":"00u1e8mutl6wlH3lL4x7","displayName":"Blair Lunceford","urn:ietf:params:scim:schemas:extension:enterprise:2.0:User":{"manager":{"value":"2","displayName":"Kathleen Chung"},"division":"Engineering","department":"Customer Success"}}},"event":"dsync.user.created"}",
      #     sig_header: 't=1626125972272, v1=80f7ab7efadc306eb5797c588cee9410da9be4416782b497bf1e1bf4175fb928',
      #     secret: 'LJlTiC19GmCKWs8AE0IaOQcos',
      #   )
      #
      #   => #<WorkOS::Webhook:0x00007fa64b980910 @event="dsync.user.created", @data={:id=>"directory_user_01FAEAJCR3ZBZ30D8BD1924TVG", :state=>"active", :emails=>[{:type=>"work", :value=>"blair@foo-corp.com", :primary=>true}], :idp_id=>"00u1e8mutl6wlH3lL4x7", :object=>"directory_user", :username=>"blair@foo-corp.com", :last_name=>"Lunceford", :first_name=>"Blair", :directory_id=>"directory_01F9M7F68PZP8QXP8G7X5QRHS7", :raw_attributes=>{:name=>{:givenName=>"Blair", :familyName=>"Lunceford", :middleName=>"Elizabeth", :honorificPrefix=>"Ms."}, :title=>"Developer Success Engineer", :active=>true, :emails=>[{:type=>"work", :value=>"blair@foo-corp.com", :primary=>true}], :groups=>[], :locale=>"en-US", :schemas=>["urn:ietf:params:scim:schemas:core:2.0:User", "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"], :userName=>"blair@foo-corp.com", :addresses=>[{:region=>"CO", :primary=>true, :locality=>"Steamboat Springs", :postalCode=>"80487"}], :externalId=>"00u1e8mutl6wlH3lL4x7", :displayName=>"Blair Lunceford", :"urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"=>{:manager=>{:value=>"2", :displayName=>"Kathleen Chung"}, :division=>"Engineering", :department=>"Customer Success"}}}>
      #
      # @return [WorkOS::Webhook]
      # rubocop:enable Layout/LineLength
      sig do
        params(
          payload: String,
          sig_header: String,
          secret: String,
          tolerance: Integer,
        ).returns(WorkOS::Webhook)
      end
      def construct_event(
        payload:,
        sig_header:,
        secret:,
        tolerance: DEFAULT_TOLERANCE
      )
        verify_header(payload: payload, sig_header: sig_header, secret: secret, tolerance: tolerance)
        WorkOS::Webhook.new(payload)
      end

      # Verifies WorkOS-Signature header from request
      # rubocop:disable Layout/LineLength
      #
      # @param [String] payload The payload from the webhook sent by WorkOS. This is the RAW_POST_DATA of the request.
      # @param [String] sig_header The signature from the webhook sent by WorkOS.
      # @param [String] secret The webhook secret from the WorkOS dashboard.
      # @param [Integer] tolerance The time tolerance in seconds for the webhook.
      #
      # @example
      #   WorkOS::Webhooks.verify_header(
      #     payload: "{"id": "wh_123","data":{"id":"directory_user_01FAEAJCR3ZBZ30D8BD1924TVG","state":"active","emails":[{"type":"work","value":"blair@foo-corp.com","primary":true}],"idp_id":"00u1e8mutl6wlH3lL4x7","object":"directory_user","username":"blair@foo-corp.com","last_name":"Lunchford","first_name":"Blair","directory_id":"directory_01F9M7F68PZP8QXP8G7X5QRHS7","raw_attributes":{"name":{"givenName":"Blair","familyName":"Lunchford","middleName":"Elizabeth","honorificPrefix":"Ms."},"title":"Developer Success Engineer","active":true,"emails":[{"type":"work","value":"blair@foo-corp.com","primary":true}],"groups":[],"locale":"en-US","schemas":["urn:ietf:params:scim:schemas:core:2.0:User","urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"],"userName":"blair@foo-corp.com","addresses":[{"region":"CA","primary":true,"locality":"San Francisco","postalCode":"94016"}],"externalId":"00u1e8mutl6wlH3lL4x7","displayName":"Blair Lunchford","urn:ietf:params:scim:schemas:extension:enterprise:2.0:User":{"manager":{"value":"2","displayName":"Kate Chapman"},"division":"Engineering","department":"Customer Success"}}},"event":"dsync.user.created"}",
      #     sig_header: 't=1626125972272, v1=80f7ab7efadc306eb5797c588cee9410da9be4416782b497bf1e1bf4175fb928',
      #     secret: 'LJlTiC19GmCKWs8AE0IaOQcos',
      #   )
      #
      #   => true
      #
      # @return Boolean
      # rubocop:enable Layout/LineLength
      sig do
        params(
          payload: String,
          sig_header: String,
          secret: String,
          tolerance: Integer,
        ).returns(T::Boolean)
      end
      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def verify_header(
        payload:,
        sig_header:,
        secret:,
        tolerance: DEFAULT_TOLERANCE
      )
        begin
          timestamp, signature_hash = get_timestamp_and_signature_hash(sig_header: sig_header)
        rescue StandardError
          raise WorkOS::SignatureVerificationError.new(
            message: 'Unable to extract timestamp and signature hash from header',
          )
        end

        if signature_hash.empty?
          raise WorkOS::SignatureVerificationError.new(
            message: 'No signature hash found with expected scheme v1',
          )
        end

        timestamp_to_time = Time.at(timestamp.to_i / 1000)

        if timestamp_to_time < Time.now - tolerance
          raise WorkOS::SignatureVerificationError.new(
            message: 'Timestamp outside the tolerance zone',
          )
        end

        expected_sig = compute_signature(timestamp: timestamp, payload: payload, secret: secret)
        unless secure_compare(str_a: expected_sig, str_b: signature_hash)
          raise WorkOS::SignatureVerificationError.new(
            message: 'Signature hash does not match the expected signature hash for payload',
          )
        end

        true
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      # Extracts timestamp and signature hash from WorkOS-Signature header
      #
      # @param [String] sig_header The signature from the webhook sent by WorkOS.
      #
      # @example
      #   WorkOS::Webhooks.get_timestamp_and_signature_hash(
      #     sig_header: 't=1626125972272, v1=80f7ab7efadc306eb5797c588cee9410da9be4416782b497bf1e1bf4175fb928',
      #   )
      #
      #   => ['1626125972272', '80f7ab7efadc306eb5797c588cee9410da9be4416782b497bf1e1bf4175fb928']
      #
      # @return Array
      sig do
        params(
          sig_header: String,
        ).returns([String, String])
      end
      def get_timestamp_and_signature_hash(
        sig_header:
      )
        timestamp, signature_hash = sig_header.split(', ')

        if timestamp.nil? || signature_hash.nil?
          raise WorkOS::SignatureVerificationError.new(
            message: 'Unable to extract timestamp and signature hash from header',
          )
        end

        timestamp = timestamp.sub('t=', '')
        signature_hash = signature_hash.sub('v1=', '')

        [timestamp, signature_hash]
      end

      # Computes expected signature
      # rubocop:disable Layout/LineLength
      #
      # @param [String] timestamp The timestamp from the webhook signature.
      # @param [String] payload The payload from the webhook sent by WorkOS. This is the RAW_POST_DATA of the request.
      # @param [String] secret The webhook secret from the WorkOS dashboard.
      #
      # @example
      #   WorkOS::Webhooks.compute_signature(
      #     timestamp: '1626125972272',
      #     payload: "{"id": "wh_123","data":{"id":"directory_user_01FAEAJCR3ZBZ30D8BD1924TVG","state":"active","emails":[{"type":"work","value":"blair@foo-corp.com","primary":true}],"idp_id":"00u1e8mutl6wlH3lL4x7","object":"directory_user","username":"blair@foo-corp.com","last_name":"Lunchford","first_name":"Blair","directory_id":"directory_01F9M7F68PZP8QXP8G7X5QRHS7","raw_attributes":{"name":{"givenName":"Blair","familyName":"Lunchford","middleName":"Elizabeth","honorificPrefix":"Ms."},"title":"Developer Success Engineer","active":true,"emails":[{"type":"work","value":"blair@foo-corp.com","primary":true}],"groups":[],"locale":"en-US","schemas":["urn:ietf:params:scim:schemas:core:2.0:User","urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"],"userName":"blair@foo-corp.com","addresses":[{"region":"CA","primary":true,"locality":"San Francisco","postalCode":"94016"}],"externalId":"00u1e8mutl6wlH3lL4x7","displayName":"Blair Lunchford","urn:ietf:params:scim:schemas:extension:enterprise:2.0:User":{"manager":{"value":"2","displayName":"Kate Chapman"},"division":"Engineering","department":"Customer Success"}}},"event":"dsync.user.created"}",
      #     secret: 'LJlTiC19GmCKWs8AE0IaOQcos',
      #   )
      #
      #   => '80f7ab7efadc306eb5797c588cee9410da9be4416782b497bf1e1bf4175fb928'
      #
      # @return String
      # rubocop:enable Layout/LineLength
      sig do
        params(
          timestamp: String,
          payload: String,
          secret: String,
        ).returns(String)
      end
      def compute_signature(
        timestamp:,
        payload:,
        secret:
      )
        unhashed_string = "#{timestamp}.#{payload}"
        digest = OpenSSL::Digest.new('sha256')
        OpenSSL::HMAC.hexdigest(digest, secret, unhashed_string)
      end

      # Constant time string comparison to prevent timing attacks
      # Code borrowed from ActiveSupport
      sig do
        params(
          str_a: String,
          str_b: String,
        ).returns(T::Boolean)
      end
      def secure_compare(
        str_a:,
        str_b:
      )
        return false unless str_a.bytesize == str_b.bytesize

        l = T.unsafe(str_a.unpack("C#{str_a.bytesize}"))

        res = 0
        str_b.each_byte { |byte| res |= byte ^ l.shift }

        res.zero?
      end
    end
  end
end
