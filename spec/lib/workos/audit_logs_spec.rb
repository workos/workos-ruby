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

            expect(response.code).to eq '201'
          end
        end
      end

      context 'without idempotency key' do
        it 'creates an event with auto-generated idempotency_key' do
          allow(SecureRandom).to receive(:uuid).and_return('test-uuid-1234')

          request = double('request')
          expect(described_class).to receive(:post_request).with(
            path: '/audit_logs/events',
            auth: true,
            idempotency_key: 'test-uuid-1234',
            body: hash_including(organization_id: 'org_123'),
          ).and_return(request)

          allow(described_class).to receive(:execute_request).and_return(double(code: '201'))

          described_class.create_event(
            organization: 'org_123',
            event: valid_event,
          )
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

      context 'with retry logic using same idempotency key' do
        it 'retries with the same idempotency key on retryable errors' do
          allow(described_class).to receive(:client).and_return(double('client'))

          call_count = 0
          allow(described_class.client).to receive(:request) do |request|
            call_count += 1
            # Verify the same idempotency key is used on every retry
            expect(request['Idempotency-Key']).to eq('test-idempotency-key')

            if call_count < 3
              # Return 500 error for first 2 attempts
              response = double('response', code: '500', body: '{"message": "Internal Server Error"}')
              allow(response).to receive(:[]).with('x-request-id').and_return('test-request-id')
              allow(response).to receive(:[]).with('Retry-After').and_return(nil)
              response
            else
              # Success on 3rd attempt
              double('response', code: '201', body: '{}')
            end
          end

          expect(described_class).to receive(:sleep).exactly(2).times

          response = described_class.create_event(
            organization: 'org_123',
            event: valid_event,
            idempotency_key: 'test-idempotency-key',
          )

          expect(response.code).to eq('201')
          expect(call_count).to eq(3)
        end
      end

      context 'with retry limit exceeded' do
        it 'stops retrying after hitting retry limit' do
          allow(described_class).to receive(:client).and_return(double('client'))

          call_count = 0
          allow(described_class.client).to receive(:request) do |request|
            call_count += 1
            expect(request['Idempotency-Key']).to eq('test-idempotency-key')

            response = double('response', code: '503', body: '{"message": "Service Unavailable"}')
            allow(response).to receive(:[]).with('x-request-id').and_return('test-request-id')
            allow(response).to receive(:[]).with('Retry-After').and_return(nil)
            response
          end

          expect(described_class).to receive(:sleep).exactly(3).times

          expect do
            described_class.create_event(
              organization: 'org_123',
              event: valid_event,
              idempotency_key: 'test-idempotency-key',
            )
          end.to raise_error(WorkOS::APIError)

          # Should make 4 total attempts: 1 initial + 3 retries
          expect(call_count).to eq(4)
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
