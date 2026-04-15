# frozen_string_literal: true

require "test_helper"

class TestEvent < WorkOS::TestCase
  def test_list_events_with_no_options_raises_argument_error
    VCR.use_cassette "events/list_events_with_no_options" do
      assert_raises(ArgumentError) do
        WorkOS::Events.list_events
      end
    end
  end

  def test_list_events_with_event
    VCR.use_cassette "events/list_events_with_event" do
      events = WorkOS::Events.list_events(
        events: ["connection.activated"]
      )

      assert_equal 1, events.data.size
    end
  end

  def test_list_events_with_after
    VCR.use_cassette "events/list_events_with_after" do
      events = WorkOS::Events.list_events(
        after: "event_01FGCPNV312FHFRCX0BYWHVSE1",
        events: ["dsync.user.created"]
      )

      assert_equal 1, events.data.size
    end
  end

  def test_list_events_with_range_start_and_range_end
    VCR.use_cassette "events/list_events_with_range" do
      events = WorkOS::Events.list_events(
        events: ["dsync.user.created"],
        range_start: "2023-01-01T00:00:00Z",
        range_end: "2023-01-03T00:00:00Z"
      )

      assert_equal 1, events.data.size
    end
  end

  def test_list_events_with_organization_id
    VCR.use_cassette "events/list_events_with_organization_id" do
      events = WorkOS::Events.list_events(
        events: ["dsync.user.created"],
        organization_id: "org_1234"
      )

      assert_equal 1, events.data.size
    end
  end
end
