# frozen_string_literal: true

describe WorkOS::Portal do
  it_behaves_like 'client'

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

      describe 'with the audit_logs intent' do
        it 'returns an Admin Portal link' do
          VCR.use_cassette 'portal/generate_link_audit_logs', match_requests_on: %i[path body] do
            portal_link = described_class.generate_link(
              intent: 'audit_logs',
              organization: organization,
            )

            expect(portal_link).to eq(
              'https://id.workos.com/portal/launch?secret=secret',
            )
          end
        end
      end

      describe 'with the certificate_renewal intent' do
        it 'returns an Admin Portal link' do
          VCR.use_cassette 'portal/generate_link_certificate_renewal', match_requests_on: %i[path body] do
            portal_link = described_class.generate_link(
              intent: 'certificate_renewal',
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
end
