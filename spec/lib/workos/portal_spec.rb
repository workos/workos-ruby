# frozen_string_literal: true
# typed: false

describe WorkOS::Portal do
  before :all do
    WorkOS.key = 'test'
  end

  after :all do
    WorkOS.key = nil
  end

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

  describe '.generate_link' do
    let(:organization) { 'org_01EHQMYV6MBK39QC5PZXHY59C3' }

    describe 'with a valid organization' do
      context 'with the sso intent' do
        it 'returns an Admin Portal link' do
          VCR.use_cassette 'portal/generate_link_sso' do
            portal_link = described_class.generate_link(
              intent: 'sso',
              organization: organization,
            )

            expect(portal_link).to eq(
              'https://id.workos.com/portal/launch?secret=secret',
            )
          end
        end
      end

      describe 'with the dsync intent' do
        it 'returns an Admin Portal link' do
          VCR.use_cassette 'portal/generate_link_dsync' do
            portal_link = described_class.generate_link(
              intent: 'dsync',
              organization: organization,
            )

            expect(portal_link).to eq(
              'https://id.workos.com/portal/launch?secret=secret',
            )
          end
        end
      end
    end

    describe 'with an invalid organization' do
      it 'raises an error' do
        VCR.use_cassette 'portal/generate_link_invalid' do
          expect do
            described_class.generate_link(
              intent: 'sso',
              organization: 'bogus-id',
            )
          end.to raise_error(
            WorkOS::InvalidRequestError,
            /Could not find an organization with the id, bogus-id/,
          )
        end
      end
    end

    describe 'with an invalid intent' do
      it 'raises an error' do
        expect do
          described_class.generate_link(
            intent: 'bogus-intent',
            organization: organization,
          )
        end.to raise_error(
          ArgumentError,
          /bogus-intent is not a valid value/,
        )
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
end
