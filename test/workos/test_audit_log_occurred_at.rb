# frozen_string_literal: true

# @oagen-ignore-file
require "test_helper"

class AuditLogOccurredAtTest < Minitest::Test
  def test_omitted_timestamp_is_absent_from_serialized_model
    model = WorkOS::AuditLogEvent.new({action: "user.signed_in"})

    refute model.to_h.key?(:occurred_at)
  end

  def test_explicit_timestamp_is_preserved
    timestamp = "2026-11-03T12:34:56.789Z"
    model = WorkOS::AuditLogEvent.new({action: "user.signed_in", occurred_at: timestamp})

    assert_equal timestamp, model.to_h[:occurred_at]
  end
end
