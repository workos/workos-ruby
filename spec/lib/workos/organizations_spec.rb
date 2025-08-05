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

        context 'with external_id' do
          it 'creates an organization with external_id' do
            VCR.use_cassette 'organization/create_with_external_id' do
              organization = described_class.create_organization(
                name: 'Test Organization with External ID',
                external_id: 'ext_org_123',
              )

              expect(organization.id).to start_with('org_')
              expect(organization.name).to eq('Test Organization with External ID')
              expect(organization.external_id).to eq('ext_org_123')
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
    context 'with a stripe_customer_id' do
      it 'updates the organization' do
        VCR.use_cassette 'organization/update_with_stripe_customer_id' do
          organization = described_class.update_organization(
            organization: 'org_01JJ5H14CAA2SQ5G9HNN6TBZ05',
            name: 'Test Organization',
            stripe_customer_id: 'cus_123',
          )

          expect(organization.id).to eq('org_01JJ5H14CAA2SQ5G9HNN6TBZ05')
          expect(organization.name).to eq('Test Organization')
          expect(organization.stripe_customer_id).to eq('cus_123')
        end
      end
    end
    context 'with an external_id' do
      it 'updates the organization' do
        VCR.use_cassette 'organization/update_with_external_id' do
          organization = described_class.update_organization(
            organization: 'org_01K0SQV0S6EPWK2ZDEFD1CP1JC',
            name: 'Test Organization',
            external_id: 'ext_org_456',
          )

          expect(organization.id).to eq('org_01K0SQV0S6EPWK2ZDEFD1CP1JC')
          expect(organization.name).to eq('Test Organization')
          expect(organization.external_id).to eq('ext_org_456')
        end
      end
    end

    context 'can set external_id to null explicitly' do
      it 'includes external_id null in request body' do
        original_method = described_class.method(:put_request)
        allow(described_class).to receive(:put_request) do |kwargs|
          original_method.call(**kwargs)
        end

        VCR.use_cassette 'organization/update_with_external_id_null' do
          described_class.update_organization(
            organization: 'org_01K0SQV0S6EPWK2ZDEFD1CP1JC',
            name: 'Test Organization',
            external_id: nil,
          )
        end

        # Verify the spy captured the right call
        expect(described_class).to have_received(:put_request).with(
          hash_including(body: hash_including(external_id: nil)),
        )
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

      it 'returns properly initialized Role objects with all attributes' do
        VCR.use_cassette 'organization/list_organization_roles' do
          roles = described_class.list_organization_roles(organization_id: 'org_01JEXP6Z3X7HE4CB6WQSH9ZAFE')

          first_role = roles.data.first
          expect(first_role).to be_a(WorkOS::Role)
          expect(first_role.id).to eq('role_01HS1C7GRJE08PBR3M6Y0ZYGDZ')
          expect(first_role.name).to eq('Admin')
          expect(first_role.slug).to eq('admin')
          expect(first_role.description).to eq('Write access to every resource available')
          expect(first_role.permissions).to eq(['admin:all', 'read:users', 'write:users', 'manage:roles'])
          expect(first_role.type).to eq('EnvironmentRole')
          expect(first_role.created_at).to eq('2024-03-15T15:38:29.521Z')
          expect(first_role.updated_at).to eq('2024-11-14T17:08:00.556Z')
        end
      end

      it 'handles roles with empty permissions arrays' do
        VCR.use_cassette 'organization/list_organization_roles' do
          roles = described_class.list_organization_roles(organization_id: 'org_01JEXP6Z3X7HE4CB6WQSH9ZAFE')

          platform_manager_role = roles.data.find { |role| role.slug == 'org-platform-manager' }
          expect(platform_manager_role).to be_a(WorkOS::Role)
          expect(platform_manager_role.permissions).to eq([])
        end
      end

      it 'properly serializes Role objects including permissions' do
        VCR.use_cassette 'organization/list_organization_roles' do
          roles = described_class.list_organization_roles(organization_id: 'org_01JEXP6Z3X7HE4CB6WQSH9ZAFE')

          billing_role = roles.data.find { |role| role.slug == 'billing' }
          serialized = billing_role.to_json

          expect(serialized[:id]).to eq('role_01JA8GJZRDSZEB9289DQXJ3N9Z')
          expect(serialized[:name]).to eq('Billing Manager')
          expect(serialized[:slug]).to eq('billing')
          expect(serialized[:permissions]).to eq(['read:billing', 'write:billing'])
          expect(serialized[:type]).to eq('EnvironmentRole')
        end
      end
    end
  end

  describe '.list_organization_feature_flags' do
    context 'with no options' do
      it 'returns feature flags for organization' do
        expected_metadata = {
          after: nil,
          before: nil,
        }

        VCR.use_cassette 'organization/list_organization_feature_flags' do
          feature_flags = described_class.list_organization_feature_flags(
            organization_id: 'org_01HX7Q7R12H1JMAKN75SH2G529',
          )

          expect(feature_flags.data.size).to eq(2)
          expect(feature_flags.list_metadata).to eq(expected_metadata)
        end
      end
    end

    context 'with the before option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/organizations/org_01HX7Q7R12H1JMAKN75SH2G529/feature-flags?before=before-id&'\
          'order=desc',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'organization/list_organization_feature_flags', match_requests_on: [:path] do
          feature_flags = described_class.list_organization_feature_flags(
            organization_id: 'org_01HX7Q7R12H1JMAKN75SH2G529',
            options: { before: 'before-id' },
          )

          expect(feature_flags.data.size).to eq(2)
        end
      end
    end

    context 'with the after option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/organizations/org_01HX7Q7R12H1JMAKN75SH2G529/feature-flags?after=after-id&'\
          'order=desc',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'organization/list_organization_feature_flags', match_requests_on: [:path] do
          feature_flags = described_class.list_organization_feature_flags(
            organization_id: 'org_01HX7Q7R12H1JMAKN75SH2G529',
            options: { after: 'after-id' },
          )

          expect(feature_flags.data.size).to eq(2)
        end
      end
    end

    context 'with the limit option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/organizations/org_01HX7Q7R12H1JMAKN75SH2G529/feature-flags?limit=10&'\
          'order=desc',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'organization/list_organization_feature_flags', match_requests_on: [:path] do
          feature_flags = described_class.list_organization_feature_flags(
            organization_id: 'org_01HX7Q7R12H1JMAKN75SH2G529',
            options: { limit: 10 },
          )

          expect(feature_flags.data.size).to eq(2)
        end
      end
    end

    context 'with multiple pagination options' do
      it 'forms the proper request to the API' do
        request_args = [
          '/organizations/org_01HX7Q7R12H1JMAKN75SH2G529/feature-flags?after=after-id&'\
          'limit=5&order=asc',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'organization/list_organization_feature_flags', match_requests_on: [:path] do
          feature_flags = described_class.list_organization_feature_flags(
            organization_id: 'org_01HX7Q7R12H1JMAKN75SH2G529',
            options: { after: 'after-id', limit: 5, order: 'asc' },
          )

          expect(feature_flags.data.size).to eq(2)
        end
      end
    end
  end
end
