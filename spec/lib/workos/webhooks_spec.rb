# frozen_string_literal: true
# typed: false

require 'json'
require 'openssl'

describe WorkOS::Webhooks do
  describe '.validate_timestamp' do
    context 'with a timestamp in allowed time' do
      it 'returns true' do
        validate_timestamp = described_class.validate_timestamp(
          signature: "t=#{Time.now.to_i * 1000}, v1=80f7ab7efadc306eb5797c588cee9410da9be4416782b497bf1e1bf4175fb928",
        )

        expect(validate_timestamp).to eq(true)
      end
    end

    context 'with a max_seconds_since_issued parameter' do
      it 'returns true' do
        validate_timestamp = described_class.validate_timestamp(
          signature: "t=#{Time.now.to_i * 1000}, v1=80f7ab7efadc306eb5797c588cee9410da9be4416782b497bf1e1bf4175fb928",
          max_seconds_since_issued: 60 * 5,
        )

        expect(validate_timestamp).to eq(true)
      end
    end

    context 'with a timestamp outside the allowed time' do
      it 'returns false' do
        validate_timestamp = described_class.validate_timestamp(
          signature: 't=1626125972272, v1=80f7ab7efadc306eb5797c588cee9410da9be4416782b497bf1e1bf4175fb928',
        )

        expect(validate_timestamp).to eq(false)
      end
    end
  end

  # rubocop:disable Layout/LineLength
  describe '.validate_signature_hash' do
    context 'with the correct signature and body' do
      it 'returns true' do
        validate_signature_hash = described_class.validate_signature_hash(
          signature: 't=1626125972272, v1=80f7ab7efadc306eb5797c588cee9410da9be4416782b497bf1e1bf4175fb928',
          body: '{"data":{"id":"directory_user_01FAEAJCR3ZBZ30D8BD1924TVG","state":"active","emails":[{"type":"work","value":"blair@foo-corp.com","primary":true}],"idp_id":"00u1e8mutl6wlH3lL4x7","object":"directory_user","username":"blair@foo-corp.com","last_name":"Lunceford","first_name":"Blair","directory_id":"directory_01F9M7F68PZP8QXP8G7X5QRHS7","raw_attributes":{"name":{"givenName":"Blair","familyName":"Lunceford","middleName":"Elizabeth","honorificPrefix":"Ms."},"title":"Developer Success Engineer","active":true,"emails":[{"type":"work","value":"blair@foo-corp.com","primary":true}],"groups":[],"locale":"en-US","schemas":["urn:ietf:params:scim:schemas:core:2.0:User","urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"],"userName":"blair@foo-corp.com","addresses":[{"region":"CO","primary":true,"locality":"Steamboat Springs","postalCode":"80487"}],"externalId":"00u1e8mutl6wlH3lL4x7","displayName":"Blair Lunceford","urn:ietf:params:scim:schemas:extension:enterprise:2.0:User":{"manager":{"value":"2","displayName":"Kathleen Chung"},"division":"Engineering","department":"Customer Success"}}},"event":"dsync.user.created"}',
          webhook_secret: 'FrQWzvMo0eqse22Ceyia2uuww',
        )

        expect(validate_signature_hash).to eq(true)
      end
    end

    context 'with a correct signature and incorrect body' do
      it 'returns false' do
        validate_signature_hash = described_class.validate_signature_hash(
          signature: 't=1626125972272, v1=80f7ab7efadc306eb5797c588cee9410da9be4416782b497bf1e1bf4175fb928',
          body: '{"data":"invalid"}',
          webhook_secret: 'FrQWzvMo0eqse22Ceyia2uuww',
        )

        expect(validate_signature_hash).to eq(false)
      end
    end

    context 'with an incorrect timestamp and correct body' do
      it 'returns false' do
        validate_signature_hash = described_class.validate_signature_hash(
          signature: 't=9999, v1=80f7ab7efadc306eb5797c588cee9410da9be4416782b497bf1e1bf4175fb928',
          body: '{"data":{"id":"directory_user_01FAEAJCR3ZBZ30D8BD1924TVG","state":"active","emails":[{"type":"work","value":"blair@foo-corp.com","primary":true}],"idp_id":"00u1e8mutl6wlH3lL4x7","object":"directory_user","username":"blair@foo-corp.com","last_name":"Lunceford","first_name":"Blair","directory_id":"directory_01F9M7F68PZP8QXP8G7X5QRHS7","raw_attributes":{"name":{"givenName":"Blair","familyName":"Lunceford","middleName":"Elizabeth","honorificPrefix":"Ms."},"title":"Developer Success Engineer","active":true,"emails":[{"type":"work","value":"blair@foo-corp.com","primary":true}],"groups":[],"locale":"en-US","schemas":["urn:ietf:params:scim:schemas:core:2.0:User","urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"],"userName":"blair@foo-corp.com","addresses":[{"region":"CO","primary":true,"locality":"Steamboat Springs","postalCode":"80487"}],"externalId":"00u1e8mutl6wlH3lL4x7","displayName":"Blair Lunceford","urn:ietf:params:scim:schemas:extension:enterprise:2.0:User":{"manager":{"value":"2","displayName":"Kathleen Chung"},"division":"Engineering","department":"Customer Success"}}},"event":"dsync.user.created"}',
          webhook_secret: 'FrQWzvMo0eqse22Ceyia2uuww',
        )

        expect(validate_signature_hash).to eq(false)
      end
    end

    context 'with an incorrect webhook secret' do
      it 'returns false' do
        validate_signature_hash = described_class.validate_signature_hash(
          signature: 't=1626125972272, v1=80f7ab7efadc306eb5797c588cee9410da9be4416782b497bf1e1bf4175fb928',
          body: '{"data":{"id":"directory_user_01FAEAJCR3ZBZ30D8BD1924TVG","state":"active","emails":[{"type":"work","value":"blair@foo-corp.com","primary":true}],"idp_id":"00u1e8mutl6wlH3lL4x7","object":"directory_user","username":"blair@foo-corp.com","last_name":"Lunceford","first_name":"Blair","directory_id":"directory_01F9M7F68PZP8QXP8G7X5QRHS7","raw_attributes":{"name":{"givenName":"Blair","familyName":"Lunceford","middleName":"Elizabeth","honorificPrefix":"Ms."},"title":"Developer Success Engineer","active":true,"emails":[{"type":"work","value":"blair@foo-corp.com","primary":true}],"groups":[],"locale":"en-US","schemas":["urn:ietf:params:scim:schemas:core:2.0:User","urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"],"userName":"blair@foo-corp.com","addresses":[{"region":"CO","primary":true,"locality":"Steamboat Springs","postalCode":"80487"}],"externalId":"00u1e8mutl6wlH3lL4x7","displayName":"Blair Lunceford","urn:ietf:params:scim:schemas:extension:enterprise:2.0:User":{"manager":{"value":"2","displayName":"Kathleen Chung"},"division":"Engineering","department":"Customer Success"}}},"event":"dsync.user.created"}',
          webhook_secret: 'invalid',
        )

        expect(validate_signature_hash).to eq(false)
      end
    end
  end
  # rubocop:enable Layout/LineLength
end
