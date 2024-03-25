# frozen_string_literal: true

describe WorkOS::AuditLogs do
  it_behaves_like 'client'

  before do
    WorkOS.configure do |config|
      config.key = 'example_api_key'
    end
  end

  describe '.create_event' do
    context 'with valid event payload' do
      let(:valid_event) do
        {
          action: 'user.signed_in',
          occurred_at: '2022-08-22T15:04:19.704Z',
          actor: {
            id: 'user_123',
            type: 'user',
            name: 'User',
            metadata: {
              foo: 'bar',
            },
          },
          targets: [{
            id: 'team_123',
            type: 'team',
            name: 'Team',
            metadata: {
              foo: 'bar',
            },
          }],
          context: {
            location: '1.1.1.1',
            user_agent: 'Mozilla',
          },
        }
      end

      context 'with idempotency key' do
        it 'creates an event' do
          VCR.use_cassette 'audit_logs/create_event_custom_idempotency_key', match_requests_on: %i[path body] do
            response = described_class.create_event(
              organization: 'org_123',
              event: valid_event,
              idempotency_key: 'idempotency_key',
            )

            expect(response.code).to eq "201"
          end
        end
      end

      context 'without idempotency key' do
        it 'creates an event' do
          VCR.use_cassette 'audit_logs/create_event', match_requests_on: %i[path body] do
            response = described_class.create_event(
              organization: 'org_123',
              event: valid_event,
            )

            expect(response.code).to eq "201"
          end
        end
      end

      context 'with invalid event' do
        it 'returns error' do
          VCR.use_cassette 'audit_logs/create_event_invalid', match_requests_on: %i[path body] do
            described_class.create_event(
              organization: 'org_123',
              event: valid_event,
            )
          rescue WorkOS::InvalidRequestError => e
            expect(
              e.message,
            ).to eq 'Status 400, Invalid Audit Log event - request ID: 1cf9b8e7-5910-4a6d-a333-46bcf841422e'
            expect(e.code).to eq 'invalid_audit_log'
            expect(e.errors.count).to eq 1
          end
        end
      end
    end
  end

  describe '.create_export' do
    context 'without filters applied' do
      it 'creates an event' do
        VCR.use_cassette 'audit_logs/create_export', match_requests_on: %i[path body] do
          audit_log_export = described_class.create_export(
            organization: 'org_123',
            range_start: '2022-06-22T15:04:19.704Z',
            range_end: '2022-08-22T15:04:19.704Z',
          )

          expect(audit_log_export).to have_attributes(
            object: 'audit_log_export',
            id: 'audit_log_export_123',
            state: 'pending',
            url: nil,
            created_at: '2022-08-22T15:04:19.704Z',
            updated_at: '2022-08-22T15:04:19.704Z',
          )
        end
      end
    end

    context 'with filters applied' do
      it 'creates an export' do
        VCR.use_cassette 'audit_logs/create_export_with_filters', match_requests_on: %i[path body] do
          audit_log_export = described_class.create_export(
            organization: 'org_123',
            range_start: '2022-06-22T15:04:19.704Z',
            range_end: '2022-08-22T15:04:19.704Z',
            actions: ['user.signed_in'],
            actors: ['Jon Smith'],
            actor_names: ['Jon Smith'],
            actor_ids: ['user_123'],
            targets: %w[user team],
          )

          expect(audit_log_export.object).to eq 'audit_log_export'
          expect(audit_log_export.id).to eq 'audit_log_export_123'
          expect(audit_log_export.state).to eq 'pending'
          expect(audit_log_export.url).to eq nil
          expect(audit_log_export.created_at).to eq '2022-08-22T15:04:19.704Z'
          expect(audit_log_export.updated_at).to eq '2022-08-22T15:04:19.704Z'
        end
      end
    end
  end

  describe '.get_export' do
    it 'returns an export' do
      VCR.use_cassette 'audit_logs/get_export', match_requests_on: %i[path] do
        audit_log_export = described_class.get_export(
          id: 'audit_log_export_123',
        )

        expect(audit_log_export.object).to eq 'audit_log_export'
        expect(audit_log_export.id).to eq 'audit_log_export_123'
        expect(audit_log_export.state).to eq 'ready'
        expect(audit_log_export.url).to eq 'https://audit-logs.com/download.csv'
        expect(audit_log_export.created_at).to eq '2022-08-22T15:04:19.704Z'
        expect(audit_log_export.updated_at).to eq '2022-08-22T15:04:19.704Z'
      end
    end
  end
end
