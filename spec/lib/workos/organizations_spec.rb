# frozen_string_literal: true

describe WorkOS::Organizations do
  it_behaves_like 'client'

  describe '.create_organization' do
    context 'with valid payload' do
      context 'with no idempotency key' do
        it 'creates an organization' do
          VCR.use_cassette 'organization/create' do
            organization = described_class.create_organization(
              domains: ['example.io'],
              name: 'Test Organization',
            )

            expect(organization.id).to eq('org_01FCPEJXEZR4DSBA625YMGQT9N')
            expect(organization.name).to eq('Test Organization')
            expect(organization.domains.first[:domain]).to eq('example.io')
          end
        end

        context 'without domains' do
          it 'creates an organization' do
            VCR.use_cassette 'organization/create_without_domains' do
              organization = described_class.create_organization(
                name: 'Test Organization',
              )

              expect(organization.id).to start_with('org_')
              expect(organization.name).to eq('Test Organization')
              expect(organization.domains).to be_empty
            end
          end
        end

        context 'with domains' do
          it 'creates an organization and warns' do
            VCR.use_cassette 'organization/create_with_domains' do
              allow(Warning).to receive(:warn)

              organization = described_class.create_organization(
                domains: ['example.io'],
                name: 'Test Organization',
              )

              expect(organization.id).to start_with('org_')
              expect(organization.name).to eq('Test Organization')
              expect(organization.domains.first[:domain]).to eq('example.io')

              expect(Warning).to have_received(:warn).with(
                "[DEPRECATION] `domains` is deprecated. Use `domain_data` instead.\n",
                any_args,
              )
            end
          end
        end

        context 'with domain_data' do
          it 'creates an organization' do
            VCR.use_cassette 'organization/create_with_domain_data' do
              organization = described_class.create_organization(
                domain_data: [{ domain: 'example.io', state: 'verified' }],
                name: 'Test Organization',
              )

              expect(organization.id).to start_with('org_')
              expect(organization.name).to eq('Test Organization')
              expect(organization.domains.first).to include(
                domain: 'example.io', state: 'verified',
              )
            end
          end
        end
      end

      context 'with idempotency key' do
        context 'when idempotency key is used once' do
          it 'creates an organization' do
            VCR.use_cassette 'organization/create_with_idempotency_key' do
              organization = described_class.create_organization(
                domains: ['example.io'],
                name: 'Test Organization',
                idempotency_key: 'key',
              )

              expect(organization.name).to eq('Test Organization')
              expect(organization.domains.first[:domain]).to eq('example.io')
            end
          end
        end

        context 'when idempotency key is used more than once' do
          context 'with duplicate event payloads' do
            it 'returns the already created organization' do
              VCR.use_cassette 'organization/create_with_duplicate_idempotency_key_and_payload' do
                organization1 = described_class.create_organization(
                  domains: ['example.com'],
                  name: 'Test Organization',
                  idempotency_key: 'foo',
                )

                organization2 = described_class.create_organization(
                  domains: ['example.com'],
                  name: 'Test Organization',
                  idempotency_key: 'foo',
                )

                expect(organization1.id).to eq(organization2.id)
              end
            end
          end

          context 'with different event payloads' do
            it 'raises an error' do
              VCR.use_cassette 'organization/create_with_duplicate_idempotency_key_and_different_payload' do
                described_class.create_organization(
                  domains: ['example.me'],
                  name: 'Test Organization',
                  idempotency_key: 'bar',
                )

                expect do
                  described_class.create_organization(
                    domains: ['example.me'],
                    name: 'Organization Test',
                    idempotency_key: 'bar',
                  )
                end.to raise_error(
                  WorkOS::InvalidRequestError,
                  /Status 400, Another idempotency key \(bar\) with different request parameters was found. Please use a different idempotency key./,
                )
              end
            end
          end
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

          expect(organizations.data.size).to eq(6)
          expect(organizations.list_metadata).to eq(expected_metadata)
        end
      end
    end

    context 'with the before option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/organizations?before=before-id&'\
          'order=desc',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'organization/list', match_requests_on: [:path] do
          organizations = described_class.list_organizations(
            before: 'before-id',
          )

          expect(organizations.data.size).to eq(6)
        end
      end
    end

    context 'with the after option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/organizations?after=after-id&'\
          'order=desc',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'organization/list', match_requests_on: [:path] do
          organizations = described_class.list_organizations(after: 'after-id')

          expect(organizations.data.size).to eq(6)
        end
      end
    end

    context 'with the limit option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/organizations?limit=10&'\
          'order=desc',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'organization/list', match_requests_on: [:path] do
          organizations = described_class.list_organizations(limit: 10)

          expect(organizations.data.size).to eq(6)
        end
      end
    end
  end

  describe '.get_organization' do
    context 'with a valid id' do
      it 'gets the organization details' do
        VCR.use_cassette('organization/get') do
          organization = described_class.get_organization(
            id: 'org_01F9293WD2PDEEV4Y625XPZVG7',
          )

          expect(organization.id).to eq('org_01F9293WD2PDEEV4Y625XPZVG7')
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
            WorkOS::NotFoundError,
            'Status 404, Not Found - request ID: ',
          )
        end
      end
    end
  end

  describe '.update_organization' do
    context 'with valid payload' do
      it 'updates the organization' do
        VCR.use_cassette 'organization/update' do
          organization = described_class.update_organization(
            organization: 'org_01F6Q6TFP7RD2PF6J03ANNWDKV',
            domains: ['example.me'],
            name: 'Test Organization',
          )

          expect(organization.id).to eq('org_01F6Q6TFP7RD2PF6J03ANNWDKV')
          expect(organization.name).to eq('Test Organization')
          expect(organization.domains.first[:domain]).to eq('example.me')
        end
      end
    end
    context 'without a name' do
      it 'updates the organization' do
        VCR.use_cassette 'organization/update_without_name' do
          organization = described_class.update_organization(
            organization: 'org_01F6Q6TFP7RD2PF6J03ANNWDKV',
            domains: ['example.me'],
          )

          expect(organization.id).to eq('org_01F6Q6TFP7RD2PF6J03ANNWDKV')
          expect(organization.name).to eq('Test Organization')
          expect(organization.domains.first[:domain]).to eq('example.me')
        end
      end
    end
  end

  describe '.delete_organization' do
    context 'with a valid id' do
      it 'returns true' do
        VCR.use_cassette('organization/delete') do
          response = described_class.delete_organization(
            id: 'org_01F4A8TD0B4N1Y9SJ8SH635HDB',
          )

          expect(response).to be(true)
        end
      end
    end

    context 'with an invalid id' do
      it 'returns false' do
        VCR.use_cassette('organization/delete_invalid') do
          expect do
            described_class.delete_organization(id: 'invalid')
          end.to raise_error(
            WorkOS::NotFoundError,
            'Status 404, Not Found - request ID: ',
          )
        end
      end
    end
  end

  describe '.list_organization_roles' do
    context 'with no options' do
      it 'returns roles for organization' do
        expected_metadata = {
          after: nil,
          before: nil,
        }

        VCR.use_cassette 'organization/list_organization_roles' do
          roles = described_class.list_organization_roles(organization_id: 'org_01JEXP6Z3X7HE4CB6WQSH9ZAFE')

          expect(roles.data.size).to eq(7)
          expect(roles.list_metadata).to eq(expected_metadata)
        end
      end
    end
  end
end
