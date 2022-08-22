# frozen_string_literal: true
# typed: false

describe WorkOS::AuditLogs do
  it_behaves_like 'client'

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
          VCR.use_cassette 'audit_logs/create_event_custom_idempotency_key', match_requests_on: %i[path body headers] do
            response = described_class.create_event(
              organization: 'org_123',
              event: valid_event,
              idempotency_key: 'idempotency_key',
            )

            expect(response.code).to eq '201'
            json = JSON.parse(response.body)
            expect(json['success']).to be true
          end
        end
      end

      context 'without idempotency key' do
        it 'creates an event' do
          VCR.use_cassette 'audit_logs/create_event', match_requests_on: %i[path body headers] do
            response = described_class.create_event(
              organization: 'org_123',
              event: valid_event,
            )

            expect(response.code).to eq '201'
            json = JSON.parse(response.body)
            expect(json['success']).to be true
          end
        end
      end

      context 'with invalid event' do
        it 'returns error' do
          VCR.use_cassette 'audit_logs/create_event_invalid', match_requests_on: %i[path body headers] do
            expect do
              described_class.create_event(
                organization: 'org_123',
                event: valid_event,
              )
            end.to raise_error(
              WorkOS::InvalidRequestError,
              /Status 400, Invalid Audit Log event./,
            )
          end
        end
      end
    end
  end
end
