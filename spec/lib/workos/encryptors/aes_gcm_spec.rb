# frozen_string_literal: true

RSpec.describe WorkOS::Encryptors::AesGcm do
  subject(:encryptor) { described_class.new }

  let(:key) { 'a' * 32 }
  let(:data) { { access_token: 'tok_123', user: { id: 'user_01' } } }

  describe '#seal' do
    it 'returns a base64-encoded string' do
      sealed = encryptor.seal(data, key)
      expect(sealed).to be_a(String)
      expect { Base64.decode64(sealed) }.not_to raise_error
    end

    it 'produces different output each time (random IV)' do
      sealed1 = encryptor.seal(data, key)
      sealed2 = encryptor.seal(data, key)
      expect(sealed1).not_to eq(sealed2)
    end
  end

  describe '#unseal' do
    it 'round-trips data correctly' do
      sealed = encryptor.seal(data, key)
      unsealed = encryptor.unseal(sealed, key)
      expect(unsealed).to eq(data)
    end

    it 'returns hash with symbolized keys' do
      sealed = encryptor.seal({ 'string_key' => 'value' }, key)
      unsealed = encryptor.unseal(sealed, key)
      expect(unsealed.keys.first).to be_a(Symbol)
    end

    it 'raises error with wrong key' do
      sealed = encryptor.seal(data, key)
      expect { encryptor.unseal(sealed, 'b' * 32) }.to raise_error(OpenSSL::Cipher::CipherError)
    end
  end
end
