# frozen_string_literal: true
# typed: false

describe WorkOS::MFA do
  it_behaves_like 'client'
  describe 'enroll_factor valid requests' do
    context 'enroll factor using valid generic parameters' do
      it 'returns a valid factor object' do
        VCR.use_cassette 'mfa/enroll_factor_generic_valid' do
          factor = described_class.enroll_factor(
            type: 'generic_otp',
          )
          expect(factor.type == 'generic_otp')
        end
      end
    end
    context 'enroll factor using valid totp parameters' do
      it 'returns a valid factor object' do
        VCR.use_cassette 'mfa/enroll_factor_totp_valid' do
          factor = described_class.enroll_factor(
            type: 'totp',
            totp_issuer: 'WorkOS',
            totp_user: 'some_user',
          )
          expect(factor.totp.class == Hash)
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
          expect(factor.sms.class == Hash)
        end
      end
    end
  end
  describe 'enroll_factor invalid responses' do
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
  describe 'challenge factor with valid requests' do
    context 'challenge with totp' do
      it 'returns challenge factor object for totp' do
        VCR.use_cassette 'mfa/challenge_factor_totp_valid' do
          challengeFactor = described_class.challenge_factor(
            authentication_factor_id: 'auth_factor_01FZ4TS0MWPZR7GATS7KCXANQZ',
          )
          expect(challengeFactor.authentication_factor_id.class.class == String)
        end
      end
    end
    context 'challenge with sms' do
      it 'returns a challenge factor object for sms' do
        VCR.use_cassette 'mfa/challenge_factor_sms_valid' do
          challengeFactor = described_class.challenge_factor(
            authentication_factor_id: 'auth_factor_01FZ4TS14D1PHFNZ9GF6YD8M1F',
            sms_template: 'Your code is {{code}}'
          )
          expect(challengeFactor.authentication_factor_id.class == String)
        end
      end
    end
    context 'challenge with generic' do
      it 'returns a valid challenge factor object for generic otp' do
        VCR.use_cassette 'mfa/challenge_factor_generic_valid' do
          challengeFactor = described_class.challenge_factor(
            authentication_factor_id: 'auth_factor_01FZ4WMXXA09XF6NK1XMKNWB3M',
          )
          puts challengeFactor.code.class
          expect(challengeFactor.code.class == String)
        end
      end
    end
  end
end