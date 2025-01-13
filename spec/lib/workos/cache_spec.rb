# frozen_string_literal: true

describe WorkOS::Cache do
  before { described_class.clear }

  describe '.write and .read' do
    it 'stores and retrieves data' do
      described_class.write('key', 'value')
      expect(described_class.read('key')).to eq('value')
    end

    it 'returns nil if key does not exist' do
      expect(described_class.read('missing')).to be_nil
    end
  end

  describe '.fetch' do
    it 'returns cached value when present and not expired' do
      described_class.write('key', 'value')
      fetch_value = described_class.fetch('key') { 'new_value' }
      expect(fetch_value).to eq('value')
    end

    it 'executes block and caches value when not present' do
      fetch_value = described_class.fetch('key') { 'new_value' }
      expect(fetch_value).to eq('new_value')
    end

    it 'executes block and caches value when force is true' do
      described_class.write('key', 'value')
      fetch_value = described_class.fetch('key', force: true) { 'new_value' }
      expect(fetch_value).to eq('new_value')
    end
  end

  describe 'expiration' do
    it 'expires values after specified time' do
      described_class.write('key', 'value', expires_in: 0.1)
      expect(described_class.read('key')).to eq('value')
      sleep 0.2
      expect(described_class.read('key')).to be_nil
    end

    it 'executes block and caches new value when expired' do
      described_class.write('key', 'old_value', expires_in: 0.1)
      sleep 0.2
      fetch_value = described_class.fetch('key') { 'new_value' }
      expect(fetch_value).to eq('new_value')
    end

    it 'does not expire values when expires_in is nil' do
      described_class.write('key', 'value', expires_in: nil)
      sleep 0.2
      expect(described_class.read('key')).to eq('value')
    end
  end

  describe '.exist?' do
    it 'returns true if key exists' do
      described_class.write('key', 'value')
      expect(described_class.exist?('key')).to be true
    end

    it 'returns false if expired' do
      described_class.write('key', 'value', expires_in: 0.1)
      sleep 0.2
      expect(described_class.exist?('key')).to be false
    end

    it 'returns false if key does not exist' do
      expect(described_class.exist?('missing')).to be false
    end
  end

  describe '.delete' do
    it 'deletes key' do
      described_class.write('key', 'value')
      described_class.delete('key')
      expect(described_class.read('key')).to be_nil
    end
  end

  describe '.clear' do
    it 'removes all keys from the cache' do
      described_class.write('key1', 'value1')
      described_class.write('key2', 'value2')

      described_class.clear

      expect(described_class.read('key1')).to be_nil
      expect(described_class.read('key2')).to be_nil
    end
  end
end
