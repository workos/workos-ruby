# frozen_string_literal: true
# typed: false

module WorkOS
  module Test
    class << self
      include Base
      include Client

      def request
        execute_request(request: post_request(path: '/events', body: {}))
      end
    end
  end
end

describe WorkOS::Base do
  describe '.execute_request' do
    context 'when unauthenticated' do
      it 'raises an error' do
        VCR.use_cassette('base/execute_request_unauthenticated') do
          expect { WorkOS::Test.request }.to raise_error(
            WorkOS::AuthenticationError,
            /Status 401, Unauthorized/,
          )
        end
      end
    end
  end
end
