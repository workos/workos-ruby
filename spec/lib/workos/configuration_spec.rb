# frozen_string_literal: true

describe WorkOS do
  describe '.configure' do
    context 'with key and no timeout' do
      before do
        WorkOS.configure do |config|
          config.key = 'example_api_key'
        end
      end

      it 'sets the key and default timeout configuration' do
        expect(WorkOS.config.key).to eq('example_api_key')
        expect(WorkOS.config.timeout).to eq(60)
      end
    end

    context 'with key and timeout' do
      before do
        WorkOS.configure do |config|
          config.key = 'example_api_key'
          config.timeout = 120
        end
      end

      it 'sets the key and timeout configuration' do
        expect(WorkOS.config.key).to eq('example_api_key')
        expect(WorkOS.config.timeout).to eq(120)
      end
    end
  end
end

describe WorkOS::Configuration do
  describe '.key!' do
    context 'with key set' do
      before do
        WorkOS.config.key = 'example_api_key'
      end

      it 'returns the key' do
        expect(WorkOS.config.key!).to eq('example_api_key')
      end
    end

    context 'with key not set' do
      before do
        WorkOS.config.key = nil
      end

      it 'throws an error' do
        expect do
          WorkOS.config.key!
        end.to raise_error(
          '`WorkOS.config.key` not set',
        )
      end
    end
  end
end
