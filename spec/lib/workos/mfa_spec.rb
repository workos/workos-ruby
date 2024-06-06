# frozen_string_literal: true

describe WorkOS::MFA do
  it_behaves_like 'client'

  describe '.enroll_factor' do
    context 'with valid generic argument' do
      it 'returns a valid factor object' do
        VCR.use_cassette 'mfa/enroll_factor_generic_valid' do
          factor = described_class.enroll_factor(
            type: 'generic_otp',
          )
          expect(factor.type == 'generic_otp')
        end
      end
    end

    context 'with valid totp arguments' do
      it 'returns a valid factor object' do
        VCR.use_cassette 'mfa/enroll_factor_totp_valid' do
          factor = described_class.enroll_factor(
            type: 'totp',
            totp_issuer: 'WorkOS',
            totp_user: 'some_user',
          )
          expect(factor.totp.instance_of?(Hash))
        end
      end
    end

    context 'with valid sms arguments' do
      it 'returns a valid factor object' do
        VCR.use_cassette 'mfa/enroll_factor_sms_valid' do
          factor = described_class.enroll_factor(
            type: 'sms',
            phone_number: '55555555555',
          )
          expect(factor.sms.instance_of?(Hash))
        end
      end
    end

    context 'when type is not sms or totp' do
      it 'returns an error' do
        expect do
          described_class.enroll_factor(
            type: 'invalid',
            phone_number: '+15005550006',
          )
        end.to raise_error(
          ArgumentError,
          "Type argument must be either 'sms' or 'totp'",
        )
      end
    end

    context 'when type is totp but missing arguments' do
      it 'returns an error' do
        expect do
          described_class.enroll_factor(
            type: 'totp',
            totp_issuer: 'WorkOS',
          )
        end.to raise_error(
          ArgumentError,
          'Incomplete arguments. Need to specify both totp_issuer and totp_user when type is totp',
        )
      end
    end
    context 'when type is sms and phone number is nil' do
      it 'returns an error' do
        expect do
          described_class.enroll_factor(
            type: 'sms',
          )
        end.to raise_error(
          ArgumentError,
          'Incomplete arguments. Need to specify phone_number when type is sms',
        )
      end
    end
  end

  describe '.challenge_factor' do
    context 'challenge with totp' do
      it 'returns challenge factor object for totp' do
        VCR.use_cassette 'mfa/challenge_factor_totp_valid' do
          challenge_factor = described_class.challenge_factor(
            authentication_factor_id: 'auth_factor_01FZ4TS0MWPZR7GATS7KCXANQZ',
          )
          expect(challenge_factor.authentication_factor_id.class.instance_of?(String))
        end
      end
    end

    context 'challenge with sms' do
      it 'returns a challenge factor object for sms' do
        VCR.use_cassette 'mfa/challenge_factor_sms_valid' do
          challenge_factor = described_class.challenge_factor(
            authentication_factor_id: 'auth_factor_01FZ4TS14D1PHFNZ9GF6YD8M1F',
            sms_template: 'Your code is {{code}}',
          )
          expect(challenge_factor.authentication_factor_id.instance_of?(String))
        end
      end
    end

    context 'challenge with generic' do
      it 'returns a valid challenge factor object for generic otp' do
        VCR.use_cassette 'mfa/challenge_factor_generic_valid' do
          challenge_factor = described_class.challenge_factor(
            authentication_factor_id: 'auth_factor_01FZ4WMXXA09XF6NK1XMKNWB3M',
          )
          expect(challenge_factor.code.instance_of?(String))
        end
      end
    end

    context 'challenge with totp mssing authentication_factor_id' do
      it 'returns argument error' do
        expect do
          described_class.challenge_factor
        end.to raise_error(
          ArgumentError,
          "Incomplete arguments: 'authentication_factor_id' is a required argument",
        )
      end
    end
  end

  describe '.verify_factor' do
    it 'throws a warning' do
      VCR.use_cassette 'mfa/verify_challenge_generic_valid' do
        allow(Warning).to receive(:warn)

        described_class.verify_factor(
          authentication_challenge_id: 'auth_challenge_01FZ4YVRBMXP5ZM0A7BP4AJ12J',
          code: '897792',
        )

        expect(Warning).to have_received(:warn).with(
          "[DEPRECATION] `verify_factor` is deprecated. Please use `verify_challenge` instead.\n",
          any_args,
        )
      end
    end

    it 'calls verify_challenge' do
      VCR.use_cassette 'mfa/verify_challenge_generic_valid' do
        verify_factor = described_class.verify_factor(
          authentication_challenge_id: 'auth_challenge_01FZ4YVRBMXP5ZM0A7BP4AJ12J',
          code: '897792',
        )
        expect(verify_factor.valid == 'true')
      end
    end
  end

  describe '.verify_challenge' do
    context 'with generic otp' do
      context 'and the challenge has not been verified' do
        it 'returns true if the code is correct' do
          VCR.use_cassette 'mfa/verify_challenge_generic_valid' do
            verify_challenge = described_class.verify_challenge(
              authentication_challenge_id: 'auth_challenge_01FZ4YVRBMXP5ZM0A7BP4AJ12J',
              code: '897792',
            )
            expect(verify_challenge.valid == 'true')
          end
        end

        it 'returns false if the code is incorrect' do
          VCR.use_cassette 'mfa/verify_challenge_generic_valid_is_false' do
            verify_challenge = described_class.verify_challenge(
              authentication_challenge_id: 'auth_challenge_01FZ4YVRBMXP5ZM0A7BP4AJ12J',
              code: '897792',
            )
            expect(verify_challenge.valid == 'false')
          end
        end
      end

      context 'and the challenge has already been verified' do
        it 'returns an error' do
          VCR.use_cassette 'mfa/verify_challenge_generic_invalid' do
            expect do
              described_class.verify_challenge(
                authentication_challenge_id: 'auth_challenge_01FZ4YVRBMXP5ZM0A7BP4AJ12J',
                code: '897792',
              )
            end.to raise_error(WorkOS::UnprocessableEntityError)
          end
        end
      end

      context 'and the challenge has expired' do
        it 'returns an error' do
          VCR.use_cassette 'mfa/verify_challenge_generic_expired' do
            expect do
              described_class.verify_challenge(
                authentication_challenge_id: 'auth_challenge_01FZ4YVRBMXP5ZM0A7BP4AJ12J',
                code: '897792',
              )
            end.to raise_error(WorkOS::UnprocessableEntityError)
          end
        end
      end

      context 'with missing code argument' do
        it 'returns an argument error' do
          expect do
            described_class.verify_challenge(
              authentication_challenge_id: 'auth_challenge_01FZ4YVRBMXP5ZM0A7BP4AJ12J',
            )
          end.to raise_error(
            ArgumentError,
            "Incomplete arguments: 'authentication_challenge_id' and 'code' are required arguments",
          )
        end
      end

      context 'with missing authentication_challenge_id argument' do
        it 'returns an error' do
          expect do
            described_class.verify_challenge(
              code: '897792',
            )
          end.to raise_error(
            ArgumentError,
            "Incomplete arguments: 'authentication_challenge_id' and 'code' are required arguments",
          )
        end
      end

      context 'with missing code and authentication_challenge_id arguments' do
        it 'returns an argument error' do
          expect do
            described_class.verify_challenge
          end.to raise_error(
            ArgumentError,
            "Incomplete arguments: 'authentication_challenge_id' and 'code' are required arguments",
          )
        end
      end
    end
  end

  describe '.get_factor' do
    context 'with a valid id' do
      it 'returns a factor' do
        VCR.use_cassette 'mfa/get_factor_valid' do
          factor = described_class.get_factor(
            id: 'auth_factor_01FZ4WMXXA09XF6NK1XMKNWB3M',
          )
          expect(factor.id.instance_of?(String))
        end
      end
    end

    context 'with an invalid id' do
      it 'returns an error' do
        VCR.use_cassette 'mfa/get_factor_invalid' do
          expect do
            described_class.get_factor(
              id: 'auth_factor_invalid',
            )
          end.to raise_error(WorkOS::NotFoundError)
        end
      end
    end
  end

  describe '.delete_factor' do
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
