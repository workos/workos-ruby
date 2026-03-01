# frozen_string_literal: true

describe WorkOS::Client do
  before do
    WorkOS.configure do |config|
      config.key = 'test_api_key'
      config.max_retries = 3
    end
  end

  after do
    # Reset to default after each test
    WorkOS.config.max_retries = 0
  end

  let(:test_module) do
    Module.new do
      extend WorkOS::Client

      def self.test_request
        request = get_request(path: '/test', auth: true)
        execute_request(request: request)
      end
    end
  end

  describe 'retry logic' do
    context 'with 500 errors' do
      it 'retries up to max_retries times' do
        allow(test_module).to receive(:client).and_return(double('client'))
        allow(test_module.client).to receive(:request) do
          double('response', code: '500', body: '{"message": "Internal Server Error"}', '[]': nil)
        end

        expect(test_module.client).to receive(:request).exactly(4).times
        expect(test_module).to receive(:sleep).exactly(3).times

        expect do
          test_module.test_request
        end.to raise_error(WorkOS::APIError)
      end
    end

    context 'with 503 errors' do
      it 'retries on service unavailable' do
        allow(test_module).to receive(:client).and_return(double('client'))
        allow(test_module.client).to receive(:request) do
          double('response', code: '503', body: '{"message": "Service Unavailable"}', '[]': nil)
        end

        expect(test_module.client).to receive(:request).exactly(4).times
        expect(test_module).to receive(:sleep).exactly(3).times

        expect do
          test_module.test_request
        end.to raise_error(WorkOS::APIError)
      end
    end

    context 'with 408 errors' do
      it 'retries with exponential backoff' do
        allow(test_module).to receive(:client).and_return(double('client'))
        allow(test_module.client).to receive(:request) do
          double('response', code: '408', body: '{"message": "Request Timeout"}', '[]': nil)
        end

        expect(test_module.client).to receive(:request).exactly(4).times
        expect(test_module).to receive(:sleep).exactly(3).times

        expect do
          test_module.test_request
        end.to raise_error(WorkOS::TimeoutError)
      end
    end

    context 'with network timeout errors' do
      it 'retries on Net::OpenTimeout' do
        allow(test_module).to receive(:client).and_return(double('client'))
        allow(test_module.client).to receive(:request).and_raise(Net::OpenTimeout)

        expect(test_module.client).to receive(:request).exactly(4).times
        expect(test_module).to receive(:sleep).exactly(3).times

        expect do
          test_module.test_request
        end.to raise_error(WorkOS::TimeoutError, 'API Timeout Error')
      end

      it 'retries on Net::ReadTimeout' do
        allow(test_module).to receive(:client).and_return(double('client'))
        allow(test_module.client).to receive(:request).and_raise(Net::ReadTimeout)

        expect(test_module.client).to receive(:request).exactly(4).times
        expect(test_module).to receive(:sleep).exactly(3).times

        expect do
          test_module.test_request
        end.to raise_error(WorkOS::TimeoutError, 'API Timeout Error')
      end

      it 'retries on Net::WriteTimeout' do
        allow(test_module).to receive(:client).and_return(double('client'))
        allow(test_module.client).to receive(:request).and_raise(Net::WriteTimeout)

        expect(test_module.client).to receive(:request).exactly(4).times
        expect(test_module).to receive(:sleep).exactly(3).times

        expect do
          test_module.test_request
        end.to raise_error(WorkOS::TimeoutError, 'API Timeout Error')
      end
    end

    context 'with successful retry' do
      it 'succeeds after retryable failure' do
        allow(test_module).to receive(:client).and_return(double('client'))

        call_count = 0
        allow(test_module.client).to receive(:request) do
          call_count += 1
          if call_count < 3
            response = double('response', code: '500', body: '{"message": "Internal Server Error"}')
            allow(response).to receive(:[]).with('x-request-id').and_return('test-request-id')
            allow(response).to receive(:[]).with('Retry-After').and_return(nil)
            response
          else
            double('response', code: '200', body: '{"success": true}')
          end
        end

        expect(test_module).to receive(:sleep).exactly(2).times

        response = test_module.test_request
        expect(response.code).to eq('200')
      end
    end

    context 'respects max_retries configuration' do
      it 'uses configured max_retries value' do
        WorkOS.config.max_retries = 2

        allow(test_module).to receive(:client).and_return(double('client'))
        allow(test_module.client).to receive(:request) do
          double('response', code: '500', body: '{"message": "Internal Server Error"}', '[]': nil)
        end

        expect(test_module.client).to receive(:request).exactly(3).times
        expect(test_module).to receive(:sleep).exactly(2).times

        expect do
          test_module.test_request
        end.to raise_error(WorkOS::APIError)
      end

      it 'does not retry when max_retries is 0' do
        WorkOS.config.max_retries = 0

        allow(test_module).to receive(:client).and_return(double('client'))
        allow(test_module.client).to receive(:request) do
          double('response', code: '500', body: '{"message": "Internal Server Error"}', '[]': nil)
        end

        expect(test_module.client).to receive(:request).once
        expect(test_module).not_to receive(:sleep)

        expect do
          test_module.test_request
        end.to raise_error(WorkOS::APIError)
      end
    end
  end

  describe '#retryable_error?' do
    it 'returns true for 5xx errors' do
      expect(test_module.send(:retryable_error?, 500)).to eq(true)
      expect(test_module.send(:retryable_error?, 503)).to eq(true)
      expect(test_module.send(:retryable_error?, 599)).to eq(true)
    end

    it 'returns true for 408 errors' do
      expect(test_module.send(:retryable_error?, 408)).to eq(true)
    end

    it 'returns true for 429 errors' do
      expect(test_module.send(:retryable_error?, 429)).to eq(true)
    end
  end
end
