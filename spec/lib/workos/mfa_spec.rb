# frozen_string_literal: true
# typed: false

describe WorkOS::MFA do
  it_behaves_like 'client'
  describe 'enroll_factor valid responses' do
    context 'enroll factor using valid totp parameters' do
      it 'returns a valid factor object' do
        VCR.use_cassette 'mfa/enroll_factor_totp_valid' do
          factor = described_class.enroll_factor(
            type: 'totp',
            totp_issuer: 'WorkOS',
            totp_user: 'some_user',
          )
          expect(factor.totp != nil)
        end
      end
    end
    context 'enroll factor using valid sms parameters' do
      it 'returns a valid factor object' do
        VCR.use_cassette 'mfa/enroll_factor_sms_valid' do
          factor = described_class.enroll_factor(
            type: 'sms',
            phone_number: '+15005550006',
          )
          expect(factor.sms != nil)
        end
      end
    end
    context 'enroll factor throws error if type is not sms or totp' do
      it 'returns an error' do
        expect do
          factor = described_class.enroll_factor(
            type: 'invalid',
            phone_number: '+15005550006',
          )
        end.to raise_error(
          ArgumentError,
          "Type parameter must be either 'sms' or 'totp'",
        )
      end
    end
    context 'enroll factor throws error if type is not sms or totp' do
      it 'returns an error' do
        expect do
          factor = described_class.enroll_factor(
            type: 'totp',
            totp_issuer: 'WorkOS',
          )
        end.to raise_error(
          ArgumentError,
          "Incomplete arguments. Need to specify both totp_issuer and totp_user when type is totp",
        )
      end
    end
    context 'enroll factor throws error if type sms and phone number is nil' do
      it 'returns an error' do
        expect do
          factor = described_class.enroll_factor(
            type: 'sms',
          )
        end.to raise_error(
          ArgumentError,
          "Incomplete arguments. Need to specify phone_number when type is sms",
        )
      end
    end
  end
end