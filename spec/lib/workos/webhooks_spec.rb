# frozen_string_literal: true
# typed: false

require 'json'
require 'openssl'

describe WorkOS::Webhooks do
  describe '.construct_event' do
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
        last_name: 'Lunceford',
        first_name: 'Blair',
        directory_id: 'directory_01F9M7F68PZP8QXP8G7X5QRHS7',
        raw_attributes: {
          name: {
            givenName: 'Blair',
            familyName: 'Lunceford',
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
            region: 'CO',
            primary: true,
            locality: 'Steamboat Springs',
            postalCode: '80487',
          }],
          externalId: '00u1e8mutl6wlH3lL4x7',
          displayName: 'Blair Lunceford',
          "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User": {
            manager: {
              value: '2',
              displayName: 'Kathleen Chung',
            },
            division: 'Engineering',
            department: 'Customer Success',
          },
        },
      }
    end

    context 'with the correct payload, sig_header, and secret' do
      it 'returns a webhook event' do
        webhook = described_class.construct_event(
          payload: @payload,
          sig_header: "t=#{@timestamp.to_i}, v1=#{@signature_hash}",
          secret: @secret,
        )

        expect(webhook.data).to eq(@expectation)
        expect(webhook.event).to eq('dsync.user.created')
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
      end
    end

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
            sig_header: "t=9999, v1=#{@signature_hash}",
            secret: @secret,
          )
        end.to raise_error(
          WorkOS::SignatureVerificationError,
          'Timestamp outside the tolerance zone',
        )
      end
    end
  end
end
