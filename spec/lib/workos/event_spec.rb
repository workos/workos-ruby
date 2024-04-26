# frozen_string_literal: true

describe WorkOS::Events do
  it_behaves_like 'client'

  describe '.list_events' do
    context 'with no options' do
      it 'returns events and metadata' do
        expected_metadata = {
          'after' => nil,
        }

        VCR.use_cassette 'events/list_events_with_no_options' do
          events = described_class.list_events

          expect(events.data.size).to eq(1)
          expect(events.list_metadata).to eq(expected_metadata)
        end
      end
    end

    context 'with event option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/events?events=connection.activated',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'events/list_events_with_event' do
          events = described_class.list_events(
            events: ['connection.activated'],
          )

          expect(events.data.size).to eq(1)
        end
      end
    end

    context 'with the after option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/events?after=event_01FGCPNV312FHFRCX0BYWHVSE1',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'events/list_events_with_after' do
          events = described_class.list_events(after: 'event_01FGCPNV312FHFRCX0BYWHVSE1')

          expect(events.data.size).to eq(1)
        end
      end
    end

    context 'with the range_start and range_end options' do
      it 'forms the proper request to the API' do
        request_args = [
          '/events?range_start=2023-01-01T00%3A00%3A00Z&range_end=2023-01-03T00%3A00%3A00Z',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'events/list_events_with_range' do
          events = described_class.list_events(
            range_start: '2023-01-01T00:00:00Z',
            range_end: '2023-01-03T00:00:00Z',
          )

          expect(events.data.size).to eq(1)
        end
      end
    end

    context 'with the organization_id option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/events?organization_id=org_1234',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'events/list_events_with_organization_id' do
          events = described_class.list_events(
            organization_id: 'org_1234'
          )

          expect(events.data.size).to eq(1)
        end
      end
    end
  end
end
