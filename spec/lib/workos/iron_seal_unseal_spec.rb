# frozen_string_literal: true

RSpec.describe WorkOS::IronSealUnseal do
  let(:password) { 'a' * 32 }
  let(:payload) { { access_token: 'tok', user: { id: 'user_01' } } }

  describe '.seal' do
    it 'produces a string with Fe26.2 prefix' do
      sealed = described_class.seal(payload, password)
      expect(sealed).to start_with(described_class::MAC_PREFIX)
    end

    it 'raises ArgumentError when password is shorter than 32 characters' do
      expect { described_class.seal(payload, 'short') }.to raise_error(
        ArgumentError, /password must be at least 32 characters/
      )
    end
  end

  describe '.unseal' do
    context 'with a valid seal (round-trip)' do
      it 'returns the decoded session hash with symbolized keys' do
        sealed = described_class.seal(payload, password)
        result = described_class.unseal(sealed, password)
        expect(result).to eq(payload)
      end

      it 'accepts sealed string with version suffix (~2)' do
        sealed = described_class.seal(payload, password)
        result = described_class.unseal("#{sealed}#{described_class::VERSION_DELIMITER}2", password)
        expect(result).to eq(payload)
      end
    end

    context 'when password is too short' do
      it 'raises ArgumentError' do
        sealed = described_class.seal(payload, password)
        expect { described_class.unseal(sealed, 'short') }.to raise_error(
          ArgumentError, /password must be at least 32/
        )
      end
    end

    context 'when sealed has wrong number of parts' do
      it 'raises UnsealError' do
        bad_seal = 'Fe26.2*a*b*c'
        expect { described_class.unseal(bad_seal, password) }.to raise_error(
          described_class::UnsealError, /Incorrect number of sealed components/
        )
      end
    end

    context 'when prefix is not Fe26.2' do
      it 'raises UnsealError' do
        sealed = described_class.seal(payload, password)
        bad_seal = sealed.sub('Fe26.2', 'Fe26.1')
        expect { described_class.unseal(bad_seal, password) }.to raise_error(
          described_class::UnsealError, /Wrong mac prefix/
        )
      end
    end

    context 'when seal is expired' do
      it 'raises UnsealError with skip_expiration: false' do
        sealed = described_class.seal(payload, password, ttl_sec: -300)
        expect { described_class.unseal(sealed, password, skip_expiration: false) }.to raise_error(
          described_class::UnsealError, /Expired seal/
        )
      end

      it 'returns session with skip_expiration: true' do
        sealed = described_class.seal(payload, password, ttl_sec: -300)
        result = described_class.unseal(sealed, password, skip_expiration: true)
        expect(result).to eq(payload)
      end
    end

    context 'when HMAC is invalid (wrong password or tampered)' do
      it 'raises UnsealError for wrong password' do
        sealed = described_class.seal(payload, password)
        wrong_password = 'b' * 32
        expect { described_class.unseal(sealed, wrong_password) }.to raise_error(
          described_class::UnsealError, /Bad hmac value/
        )
      end
    end
  end
end
