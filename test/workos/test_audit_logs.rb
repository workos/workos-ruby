# frozen_string_literal: true

require "test_helper"

class TestAuditLogs < WorkOS::TestCase
  def setup
    super
    WorkOS.configure do |config|
      config.key = "example_api_key"
    end
  end

  def valid_event
    {
      action: "user.signed_in",
      occurred_at: "2022-08-22T15:04:19.704Z",
      actor: {
        id: "user_123",
        type: "user",
        name: "User",
        metadata: {
          foo: "bar"
        }
      },
      targets: [{
        id: "team_123",
        type: "team",
        name: "Team",
        metadata: {
          foo: "bar"
        }
      }],
      context: {
        location: "1.1.1.1",
        user_agent: "Mozilla"
      }
    }
  end

  def test_create_event_with_idempotency_key
    VCR.use_cassette "audit_logs/create_event_custom_idempotency_key", match_requests_on: %i[path body] do
      response = WorkOS::AuditLogs.create_event(
        organization: "org_123",
        event: valid_event,
        idempotency_key: "idempotency_key"
      )

      assert_equal "201", response.code
    end
  end

  def test_create_event_without_idempotency_key
    VCR.use_cassette "audit_logs/create_event", match_requests_on: %i[path body] do
      response = WorkOS::AuditLogs.create_event(
        organization: "org_123",
        event: valid_event
      )

      assert_equal "201", response.code
    end
  end

  def test_create_event_with_invalid_event
    VCR.use_cassette "audit_logs/create_event_invalid", match_requests_on: %i[path body] do
      WorkOS::AuditLogs.create_event(
        organization: "org_123",
        event: valid_event
      )
    rescue WorkOS::InvalidRequestError => e
      assert_equal(
        "Status 400, Invalid Audit Log event - request ID: 1cf9b8e7-5910-4a6d-a333-46bcf841422e",
        e.message
      )
      assert_equal "invalid_audit_log", e.code
      assert_equal 1, e.errors.count
    end
  end

  def test_create_export_without_filters
    VCR.use_cassette "audit_logs/create_export", match_requests_on: %i[path body] do
      audit_log_export = WorkOS::AuditLogs.create_export(
        organization: "org_123",
        range_start: "2022-06-22T15:04:19.704Z",
        range_end: "2022-08-22T15:04:19.704Z"
      )

      assert_equal "audit_log_export", audit_log_export.object
      assert_equal "audit_log_export_123", audit_log_export.id
      assert_equal "pending", audit_log_export.state
      assert_nil audit_log_export.url
      assert_equal "2022-08-22T15:04:19.704Z", audit_log_export.created_at
      assert_equal "2022-08-22T15:04:19.704Z", audit_log_export.updated_at
    end
  end

  def test_create_export_with_filters
    VCR.use_cassette "audit_logs/create_export_with_filters", match_requests_on: %i[path body] do
      audit_log_export = WorkOS::AuditLogs.create_export(
        organization: "org_123",
        range_start: "2022-06-22T15:04:19.704Z",
        range_end: "2022-08-22T15:04:19.704Z",
        actions: ["user.signed_in"],
        actors: ["Jon Smith"],
        actor_names: ["Jon Smith"],
        actor_ids: ["user_123"],
        targets: %w[user team]
      )

      assert_equal "audit_log_export", audit_log_export.object
      assert_equal "audit_log_export_123", audit_log_export.id
      assert_equal "pending", audit_log_export.state
      assert_nil audit_log_export.url
      assert_equal "2022-08-22T15:04:19.704Z", audit_log_export.created_at
      assert_equal "2022-08-22T15:04:19.704Z", audit_log_export.updated_at
    end
  end

  def test_get_export
    VCR.use_cassette "audit_logs/get_export", match_requests_on: %i[path] do
      audit_log_export = WorkOS::AuditLogs.get_export(
        id: "audit_log_export_123"
      )

      assert_equal "audit_log_export", audit_log_export.object
      assert_equal "audit_log_export_123", audit_log_export.id
      assert_equal "ready", audit_log_export.state
      assert_equal "https://audit-logs.com/download.csv", audit_log_export.url
      assert_equal "2022-08-22T15:04:19.704Z", audit_log_export.created_at
      assert_equal "2022-08-22T15:04:19.704Z", audit_log_export.updated_at
    end
  end
end
