# frozen_string_literal: true
# typed: false

describe WorkOS::Organizations do
  describe '.create_organization' do
    context 'with valid payload' do
      it 'creates an organization' do
        VCR.use_cassette 'organization/create' do
          organization = described_class.create_organization(
            domains: ['example.com'],
            name: 'Test Organization',
          )

          expect(organization.id).to eq('org_01EHT88Z8J8795GZNQ4ZP1J81T')
          expect(organization.name).to eq('Test Organization')
          expect(organization.domains.first[:domain]).to eq('example.com')
        end
      end
    end

    context 'with an invalid payload' do
      it 'returns an error' do
        VCR.use_cassette 'organization/create_invalid' do
          expect do
            described_class.create_organization(
              domains: ['example.com'],
              name: 'Test Organization 2',
            )
          end.to raise_error(
            WorkOS::APIError,
            /An Organization with the domain example.com already exists/,
          )
        end
      end
    end
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

  describe '.get_organization' do
    context 'with a valid id' do
      it 'gets the organization details' do
        VCR.use_cassette('organization/get') do
          organization = described_class.get_organization(
            id: 'org_01EZDF20TZEJXKPSX2BJRN6TV6',
          )

          expect(organization.id).to eq('org_01EZDF20TZEJXKPSX2BJRN6TV6')
          expect(organization.name).to eq('Foo Corp')
          expect(organization.domains.first[:domain]).to eq('foo-corp.com')
        end
      end
    end

    context 'with an invalid id' do
      it 'raises an error' do
        VCR.use_cassette('organization/get_invalid') do
          expect do
            described_class.get_organization(id: 'invalid')
          end.to raise_error(
            WorkOS::APIError,
            'Status 404, Not Found - request ID: ',
          )
        end
      end
    end
  end

  describe '.update_organization' do
    context 'with valid payload' do
      it 'creates an organization' do
        VCR.use_cassette 'organization/update' do
          organization = described_class.update_organization(
            organization: 'org_01F29YJ068E52HGEB8ZQGC9MJG',
            domains: ['example.me'],
            name: 'Test Organization',
          )

          expect(organization.id).to eq('org_01F29YJ068E52HGEB8ZQGC9MJG')
          expect(organization.name).to eq('Test Organization')
          expect(organization.domains.first[:domain]).to eq('example.me')
        end
      end
    end
  end
end
