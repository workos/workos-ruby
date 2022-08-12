# frozen_string_literal: true
# typed: false

require 'json'
require 'openssl'

describe WorkOS::Webhooks do
  before(:each) do
    @payload = File.read("#{SPEC_ROOT}/support/webhook_payload.txt")
    @secret = 'secret'
    @timestamp = Time.at(Time.now.to_i * 1000)
    unhashed_string = "#{@timestamp.to_i}.#{@payload}"
    digest = OpenSSL::Digest.new('sha256')
    @signature_hash = OpenSSL::HMAC.hexdigest(digest, @secret, unhashed_string)
    @expectation = {
      id: 'directory_user_01FAEAJCR3ZBZ30D8BD1924TVG',
      state: 'active',
      emails: [{
        type: 'work',
        value: 'blair@foo-corp.com',
        primary: true,
      }],
      idp_id: '00u1e8mutl6wlH3lL4x7',
      object: 'directory_user',
      username: 'blair@foo-corp.com',
      last_name: 'Lunchford',
      first_name: 'Blair',
      directory_id: 'directory_01F9M7F68PZP8QXP8G7X5QRHS7',
      raw_attributes: {
        name: {
          givenName: 'Blair',
          familyName: 'Lunchford',
          middleName: 'Elizabeth',
          honorificPrefix: 'Ms.',
        },
        title: 'Developer Success Engineer',
        active: true,
        emails: [{
          type: 'work',
          value: 'blair@foo-corp.com',
          primary: true,
        }],
        groups: [],
        locale: 'en-US',
        schemas: [
          'urn:ietf:params:scim:schemas:core:2.0:User',
          'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User'
        ],
        userName: 'blair@foo-corp.com',
        addresses: [{
          region: 'CA',
          primary: true,
          locality: 'San Francisco',
          postalCode: '94016',
        }],
        externalId: '00u1e8mutl6wlH3lL4x7',
        displayName: 'Blair Lunchford',
        "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User": {
          manager: {
            value: '2',
            displayName: 'Kate Chapman',
          },
          division: 'Engineering',
          department: 'Customer Success',
        },
      },
    }
  end

  # rubocop:disable Metrics/BlockLength
  shared_examples 'WorkOS-Signature header failures' do
    context 'with an empty header' do
      it 'raises an error' do
        expect do
          described_class.construct_event(
            payload: @payload,
            sig_header: '',
            secret: @secret,
          )
        end.to raise_error(
          WorkOS::SignatureVerificationError,
          'Unable to extract timestamp and signature hash from header',
        )
      end
    end

    context 'with an empty signature hash' do
      it 'raises an error' do
        expect do
          described_class.construct_event(
            payload: @payload,
            sig_header: "t=#{@timestamp.to_i}, v1=",
            secret: @secret,
          )
        end.to raise_error(
          WorkOS::SignatureVerificationError,
          'No signature hash found with expected scheme v1',
        )
      end
    end

    context 'with an incorrect signature hash' do
      it 'raises an error' do
        expect do
          described_class.construct_event(
            payload: @payload,
            sig_header: "t=#{@timestamp.to_i}, v1=99999",
            secret: @secret,
          )
        end.to raise_error(
          WorkOS::SignatureVerificationError,
          'Signature hash does not match the expected signature hash for payload',
        )
      end
    end

    context 'with an incorrect payload' do
      it 'raises an error' do
        expect do
          described_class.construct_event(
            payload: 'invalid',
            sig_header: "t=#{@timestamp.to_i}, v1=#{@signature_hash}",
            secret: @secret,
          )
        end.to raise_error(
          WorkOS::SignatureVerificationError,
          'Signature hash does not match the expected signature hash for payload',
        )
      end
    end

    context 'with an incorrect webhook secret' do
      it 'raises an error' do
        expect do
          described_class.construct_event(
            payload: @payload,
            sig_header: "t=#{@timestamp.to_i}, v1=#{@signature_hash}",
            secret: 'invalid',
          )
        end.to raise_error(
          WorkOS::SignatureVerificationError,
          'Signature hash does not match the expected signature hash for payload',
        )
      end
    end

    context 'with a timestamp outside tolerance' do
      it 'raises an error' do
        expect do
          described_class.construct_event(
            payload: @payload,
            sig_header: "t=#{@timestamp.to_i - (200 * 1000)}, v1=#{@signature_hash}",
            secret: @secret,
          )
        end.to raise_error(
          WorkOS::SignatureVerificationError,
          'Timestamp outside the tolerance zone',
        )
      end
    end
  end
  # rubocop:enable Metrics/BlockLength

  describe '.construct_event' do
    it_behaves_like 'WorkOS-Signature header failures'

    context 'with the correct payload, sig_header, and secret' do
      it 'returns a webhook event' do
        webhook = described_class.construct_event(
          payload: @payload,
          sig_header: "t=#{@timestamp.to_i}, v1=#{@signature_hash}",
          secret: @secret,
        )

        expect(webhook.data).to eq(@expectation)
        expect(webhook.event).to eq('dsync.user.created')
        expect(webhook.id).to eq('wh_123')
      end
    end

    context 'with the correct payload, sig_header, secret, and tolerance' do
      it 'returns a webhook event' do
        webhook = described_class.construct_event(
          payload: @payload,
          sig_header: "t=#{@timestamp.to_i}, v1=#{@signature_hash}",
          secret: @secret,
          tolerance: 300,
        )

        expect(webhook.data).to eq(@expectation)
        expect(webhook.event).to eq('dsync.user.created')
        expect(webhook.id).to eq('wh_123')
      end
    end
  end

  describe '.verify_header' do
    it_behaves_like 'WorkOS-Signature header failures'

    it 'returns true when the signature is valid' do
      described_class.verify_header(
        payload: @payload,
        sig_header: "t=#{@timestamp.to_i}, v1=#{@signature_hash}",
        secret: @secret,
      )
    end
  end

  describe '.get_timestamp_and_signature_hash' do
    it_behaves_like 'WorkOS-Signature header failures'

    it 'returns the timestamp and signature when the signature is valid' do
      timestamp_int = @timestamp.to_i
      timestamp_and_signature = described_class.get_timestamp_and_signature_hash(
        sig_header: "t=#{timestamp_int}, v1=#{@signature_hash}",
      )

      expect(timestamp_and_signature).to eq([timestamp_int.to_s, @signature_hash])
    end
  end

  describe '.compute_signature' do
    it_behaves_like 'WorkOS-Signature header failures'

    it 'returns the computed signature' do
      timestamp_int = @timestamp.to_i
      signature = described_class.compute_signature(
        timestamp: timestamp_int.to_s,
        payload: @payload,
        secret: @secret,
      )

      expect(signature).to eq(@signature_hash)
    end
  end
end
