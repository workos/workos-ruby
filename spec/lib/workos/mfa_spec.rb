# frozen_string_literal: true
# typed: false

describe WorkOS::MFA do
  it_behaves_like 'client'
  describe 'enroll_factor valid requests' do
    context 'enroll factor using valid generic argument' do
      it 'returns a valid factor object' do
        VCR.use_cassette 'mfa/enroll_factor_generic_valid' do
          factor = described_class.enroll_factor(
            type: 'generic_otp',
          )
          expect(factor.type == 'generic_otp')
        end
      end
    end
    context 'enroll factor using valid totp arguments' do
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
    context 'enroll factor using valid sms arguments' do
      it 'returns a valid factor object' do
        VCR.use_cassette 'mfa/enroll_factor_sms_valid' do
          factor = described_class.enroll_factor(
            type: 'sms',
            phone_number: '55555555555',
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
          "Type argument must be either 'sms' or 'totp'",
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
  describe 'challenge factor with valid request arguments' do
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
          expect(challengeFactor.code.class == String)
        end
      end
    end
  end
  describe 'challenge factor with invalid arguments' do
    context 'challenge with totp mssing authentication_factor_id' do
      it 'returns argument error' do
        expect do
            challengeFactor = described_class.challenge_factor(
    
            )
          end.to raise_error(
            ArgumentError,
            "Incomplete arguments: 'authentication_factor_id' is a required argument"
          )
      end
    end
  end
  describe 'challenge factor with valid requests' do
    context 'verify generic otp' do
      it 'returns a true boolean if the challenge has not been verifed yet' do
        VCR.use_cassette 'mfa/verify_factor_generic_valid' do
          verifyFactor = described_class.verify_factor(
            authentication_challenge_id: 'auth_challenge_01FZ4YVRBMXP5ZM0A7BP4AJ12J',
            code: '897792',
          )
          expect(verifyFactor.valid == 'true')
        end
      end
    end
    context 'verify generic otp' do
      it 'returns error that the challenge has already been verfied' do
        VCR.use_cassette 'mfa/verify_factor_generic_invalid' do
          expect do
            verifyFactor = described_class.verify_factor(
              authentication_challenge_id: 'auth_challenge_01FZ4YVRBMXP5ZM0A7BP4AJ12J',
              code: '897792',
            )
          end.to raise_error(WorkOS::InvalidRequestError)
        end
      end
      context 'verify generic otp' do
        it 'returns error that the challenge has expired' do
          VCR.use_cassette 'mfa/verify_factor_generic_expired' do
            expect do
              verifyFactor = described_class.verify_factor(
                authentication_challenge_id: 'auth_challenge_01FZ4YVRBMXP5ZM0A7BP4AJ12J',
                code: '897792',
              )
            end.to raise_error(WorkOS::InvalidRequestError)
          end
        end
      end
    end
  end
  describe 'verify_factor with invalid argument' do
    context 'missing code argument' do
      it 'returns argument error' do
        expect do
            challengeFactor = described_class.verify_factor(
              authentication_challenge_id: 'auth_challenge_01FZ4YVRBMXP5ZM0A7BP4AJ12J'
            )
          end.to raise_error(
            ArgumentError, 
            "Incomplete arguments: 'authentication_challenge_id' and 'code' are required arguments"
          )
      end
    end
    context 'missing authentication_challenge_id argument' do
      it '' do
        expect do
            challengeFactor = described_class.verify_factor(
              code: '897792',
            )
          end.to raise_error(
            ArgumentError, 
            "Incomplete arguments: 'authentication_challenge_id' and 'code' are required arguments"
          )
      end
    end
    context 'missing code and authentication_challenge_id arguments' do
      it 'returns argument error' do
        expect do
            challengeFactor = described_class.verify_factor(
    
            )
          end.to raise_error(
            ArgumentError, 
            "Incomplete arguments: 'authentication_challenge_id' and 'code' are required arguments"
          )
      end
    end
  end
  describe 'tests returning and deleting a factor' do
    context 'returns a factor' do
      it 'uses get_factor to return  factor' do
        VCR.use_cassette 'mfa/get_factor_valid' do
          factor = described_class.get_factor(
            id: 'auth_factor_01FZ4WMXXA09XF6NK1XMKNWB3M',
          )
          expect(factor.id.class == String)
        end
      end
    end
    context 'invalid factor request' do
      it 'uses get_factor and throws error if id is wrong' do
        VCR.use_cassette 'mfa/get_factor_invalid' do
          expect do
            factor = described_class.get_factor(
              id: 'auth_factor_invalid',
            )
          end.to raise_error(WorkOS::APIError)
        end
      end
    end
    context 'deletes facotr' do
      it 'uses delete_factor to delete factor' do
        VCR.use_cassette 'mfa/delete_factor' do
          response = described_class.delete_factor(
            id: 'auth_factor_01FZ4WMXXA09XF6NK1XMKNWB3M',
          )
          expect(response).to be(true)
        end
      end
    end
  end
end