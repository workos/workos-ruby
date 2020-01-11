# frozen_string_literal: true
# typed: false

describe WorkOS::AuditLog do
  before(:all) do
    WorkOS.key = 'key'
  end

  after(:all) do
    WorkOS.key = nil
  end

  describe '.create_event' do
    context 'with valid event payload' do
      let(:valid_event) do
        {
          group: 'Terrace House',
          location: '1.1.1.1',
          action: 'house.created',
          action_type: 'C',
          actor_name: 'Daiki Miyagi',
          actor_id: 'user_12345',
          target_name: 'Ryota Yamasato',
          target_id: 'user_67890',
          occurred_at: '2020-01-10T15:30:00-05:00',
          metadata: {
            a: 'b',
          }
        }
      end

      context 'with idempotency key' do
        context 'when idempotency keyis used once' do
          it 'creates an event' do
            VCR.use_cassette('audit_log/create_event_custom_idempotency_key') do
              response = described_class.create_event(event: valid_event, idempotency_key: 'key')

              expect(response.code).to eq '201'
              json = JSON.parse(response.body)
              expect(json['success']).to be true
            end
          end
        end

        context 'when idempotency key is used more than once' do
          context 'with duplicate event payloads' do
            it 'creates an event' do
              VCR.use_cassette('audit_log/create_events_duplicate_idempotency_key_and_payload') do
                response1 = described_class.create_event(event: valid_event, idempotency_key: 'foo')
                response2 = described_class.create_event(event: valid_event, idempotency_key: 'foo')

                expect(response1.code).to eq '201'
                json1 = JSON.parse(response1.body)
                expect(json1['success']).to be true

                expect(response2.code).to eq '201'
                json2 = JSON.parse(response1.body)
                expect(json2['success']).to be true
              end
            end
          end

          context 'with different event payloads' do
            it 'raises an error' do
              VCR.use_cassette('audit_log/create_events_duplicate_idempotency_key_different_payload') do
                described_class.create_event(event: valid_event, idempotency_key: 'bar')

                payload = valid_event.clone
                payload[:actor_name] = 'Tetsuya Sugaya'

                expect {
                  described_class.create_event(event: payload, idempotency_key: 'bar')
                }.to raise_error(
                  WorkOS::InvalidRequestError,
                  /Status 400, Another idempotency key \(bar\) with different request parameters was found. Please use a different idempotency key./
                )
              end
            end
          end
        end
      end

      context 'with no idempotency key' do
        it 'generates an idempotency key and creates an event' do
          VCR.use_cassette('audit_log/create_event_auto_generated_idempotency_key') do
            response = described_class.create_event(event: valid_event)

            expect(response.code).to eq '201'
            json = JSON.parse(response.body)
            expect(json['success']).to be true
          end
        end
      end
    end

    context 'with invalid event payload' do
      let(:invalid_event) do
        {
          group: 'Terrace House',
          location: '1.1.1.1',
          action: 'house.created',
          actor_name: 'Daiki Miyagi',
          actor_id: 'user_12345',
          target_name: 'Ryota Yamasato',
          target_id: 'user_67890',
          occurred_at: '2020-01-10T15:30:00-05:00',
          metadata: {
            a: 'b',
          }
        }
      end

      it 'raises an error' do
        VCR.use_cassette('audit_log/create_event_invalid') do
          expect { described_class.create_event(event: invalid_event) }.to raise_error(
            WorkOS::InvalidRequestError,
            /Status 422, Validation failed \(action_type: action_type must be a string\)/
          )
        end
      end
    end
  end
end
