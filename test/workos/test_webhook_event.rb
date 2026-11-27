# frozen_string_literal: true

# @oagen-ignore-file
require "test_helper"
require "openssl"

class WebhookEventTest < Minitest::Test
  SECRET = "whsec_test_secret"

  FLAG_DATA = {
    "object" => "feature_flag",
    "id" => "flag_01EHZNVPK3SFK441A1RGBFSHRT",
    "environment_id" => "environment_01EHWNCE74X7JSDV0X3SZ3KJNY",
    "slug" => "advanced-analytics",
    "name" => "Advanced Analytics",
    "description" => "Enable advanced analytics dashboard feature",
    "owner" => {"email" => "jane@example.com", "first_name" => "Jane", "last_name" => "Doe"},
    "tags" => ["reports"],
    "enabled" => true,
    "default_value" => false,
    "created_at" => "2026-01-15T12:00:00.000Z",
    "updated_at" => "2026-01-15T12:00:00.000Z"
  }.freeze

  FLAG_RULE_DATA = {
    "object" => "flag_rule",
    "id" => "flag_rule_01EHZNVPK3SFK441A1RGBFSHRT",
    "flag_id" => "flag_01EHZNVPK3SFK441A1RGBFSHRT",
    "flag_slug" => "new-checkout",
    "environment_id" => "environment_01EHWNCE74X7JSDV0X3SZ3KJNY",
    "target_type" => "organization",
    "position" => 0,
    "value_type" => "boolean",
    "value" => false,
    "created_at" => "2026-01-15T12:00:00.000Z",
    "updated_at" => "2026-01-15T12:00:00.000Z"
  }.freeze

  FLAG_TARGET_DATA = {
    "object" => "flag_target",
    "id" => "flag_target_01EHZNVPK3SFK441A1RGBFSHRT",
    "flag_id" => "flag_01EHZNVPK3SFK441A1RGBFSHRT",
    "flag_slug" => "new-checkout",
    "environment_id" => "environment_01EHWNCE74X7JSDV0X3SZ3KJNY",
    "target_type" => "organization",
    "target_id" => "org_01EHWNCE74X7JSDV0X3SZ3KJNY",
    "created_at" => "2026-01-15T12:00:00.000Z",
    "updated_at" => "2026-01-15T12:00:00.000Z",
    "rule_id" => "flag_rule_01EHZNVPK3SFK441A1RGBFSHRT",
    "value_type" => "boolean",
    "value" => true
  }.freeze

  # event name => [expected data model, sample data]
  FEATURE_FLAG_EVENTS = {
    "feature_flags.flag.created" => ["WorkOS::FeatureFlagsFlagCreatedData", FLAG_DATA],
    "feature_flags.flag.updated" => ["WorkOS::FeatureFlagsFlagUpdatedData", FLAG_DATA],
    "feature_flags.flag.deleted" => ["WorkOS::FeatureFlagsFlagDeletedData", FLAG_DATA],
    "feature_flags.flag_rule.created" => ["WorkOS::FlagRule", FLAG_RULE_DATA],
    "feature_flags.flag_rule.updated" => ["WorkOS::FlagRule", FLAG_RULE_DATA],
    "feature_flags.flag_rule.deleted" => ["WorkOS::FlagRule", FLAG_RULE_DATA],
    "feature_flags.flag_target.created" => ["WorkOS::FlagTarget", FLAG_TARGET_DATA],
    "feature_flags.flag_target.deleted" => ["WorkOS::FlagTarget", FLAG_TARGET_DATA],
    "flag.created" => ["WorkOS::FlagCreatedData", FLAG_DATA],
    "flag.updated" => ["WorkOS::FlagUpdatedData", FLAG_DATA],
    "flag.deleted" => ["WorkOS::FlagDeletedData", FLAG_DATA],
    "flag.rule_updated" => ["WorkOS::FlagRuleUpdatedData", FLAG_DATA]
  }.freeze

  def setup
    @webhooks = WorkOS::Client.new(api_key: "sk_test_webhook").webhooks
  end

  def construct(event_name, data)
    payload = JSON.generate(
      "object" => "event",
      "id" => "event_01EHZNVPK3SFK441A1RGBFSHRT",
      "event" => event_name,
      "data" => data,
      "created_at" => "2026-01-15T12:00:00.000Z",
      "context" => {"client_id" => "client_01EHWNCE74X7JSDV0X3SZ3KJNY"}
    )
    timestamp = (Time.now.to_f * 1000).to_i
    signature = OpenSSL::HMAC.hexdigest("SHA256", SECRET, "#{timestamp}.#{payload}")
    @webhooks.construct_event(payload: payload, sig_header: "t=#{timestamp}, v1=#{signature}", secret: SECRET)
  end

  FEATURE_FLAG_EVENTS.each do |event_name, (model_name, data)|
    define_method("test_#{event_name.tr(".", "_")}_data_is_#{model_name.split("::").last}") do
      event = construct(event_name, data)

      assert_equal event_name, event.event
      assert_instance_of Object.const_get(model_name), event.data
      assert_equal data["id"], event.data.id
      assert_equal data["environment_id"], event.data.environment_id
    end
  end

  def test_flag_rule_data_exposes_rule_fields
    rule = construct("feature_flags.flag_rule.updated", FLAG_RULE_DATA).data

    assert_equal "new-checkout", rule.flag_slug
    assert_equal 0, rule.position
    assert_equal false, rule.value
  end

  def test_flag_target_data_exposes_target_fields
    target = construct("feature_flags.flag_target.created", FLAG_TARGET_DATA).data

    assert_equal "org_01EHWNCE74X7JSDV0X3SZ3KJNY", target.target_id
    assert_equal "flag_rule_01EHZNVPK3SFK441A1RGBFSHRT", target.rule_id
    assert_equal true, target.value
  end

  def test_feature_flag_data_parses_owner
    flag = construct("feature_flags.flag.created", FLAG_DATA).data

    assert_equal "advanced-analytics", flag.slug
    assert_equal "jane@example.com", flag.owner.email
  end

  def test_unknown_event_data_stays_a_hash
    event = construct("some_future.event", {"id" => "thing_01"})

    assert_equal({"id" => "thing_01"}, event.data)
  end
end
