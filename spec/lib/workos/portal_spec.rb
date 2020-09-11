# frozen_string_literal: true
# typed: false

describe WorkOS::Portal do
  before :all do
    WorkOS.key = 'test'
  end

  after :all do
    WorkOS.key = nil
  end

  describe '.list_organizations' do
    context 'with no options' do
      it 'returns organizations and metadata' do
        expected_metadata = {
          'after' => nil,
          'before' => 'before-id',
        }

        VCR.use_cassette 'organization/list' do
          organizations = described_class.list_organizations

          expect(organizations.data.size).to eq(7)
          expect(organizations.list_metadata).to eq(expected_metadata)
        end
      end
    end

    context 'with the before option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/organizations?before=before-id',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'organization/list', match_requests_on: [:path] do
          organizations = described_class.list_organizations(
            before: 'before-id',
          )

          expect(organizations.data.size).to eq(7)
        end
      end
    end

    context 'with the after option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/organizations?after=after-id',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'organization/list', match_requests_on: [:path] do
          organizations = described_class.list_organizations(after: 'after-id')

          expect(organizations.data.size).to eq(7)
        end
      end
    end

    context 'with the limit option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/organizations?limit=10',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'organization/list', match_requests_on: [:path] do
          organizations = described_class.list_organizations(limit: 10)

          expect(organizations.data.size).to eq(7)
        end
      end
    end
  end
end
