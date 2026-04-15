# frozen_string_literal: true

require "test_helper"

class TestCache < WorkOS::TestCase
  def setup
    super
    WorkOS::Cache.clear
  end

  def test_write_and_read_stores_and_retrieves_data
    WorkOS::Cache.write("key", "value")
    assert_equal "value", WorkOS::Cache.read("key")
  end

  def test_read_returns_nil_if_key_does_not_exist
    assert_nil WorkOS::Cache.read("missing")
  end

  def test_fetch_returns_cached_value_when_present_and_not_expired
    WorkOS::Cache.write("key", "value")
    fetch_value = WorkOS::Cache.fetch("key") { "new_value" }
    assert_equal "value", fetch_value
  end

  def test_fetch_executes_block_and_caches_value_when_not_present
    fetch_value = WorkOS::Cache.fetch("key") { "new_value" }
    assert_equal "new_value", fetch_value
  end

  def test_fetch_executes_block_and_caches_value_when_force_is_true
    WorkOS::Cache.write("key", "value")
    fetch_value = WorkOS::Cache.fetch("key", force: true) { "new_value" }
    assert_equal "new_value", fetch_value
  end

  def test_expires_values_after_specified_time
    WorkOS::Cache.write("key", "value", expires_in: 0.1)
    assert_equal "value", WorkOS::Cache.read("key")
    sleep 0.2
    assert_nil WorkOS::Cache.read("key")
  end

  def test_fetch_executes_block_and_caches_new_value_when_expired
    WorkOS::Cache.write("key", "old_value", expires_in: 0.1)
    sleep 0.2
    fetch_value = WorkOS::Cache.fetch("key") { "new_value" }
    assert_equal "new_value", fetch_value
  end

  def test_does_not_expire_values_when_expires_in_is_nil
    WorkOS::Cache.write("key", "value", expires_in: nil)
    sleep 0.2
    assert_equal "value", WorkOS::Cache.read("key")
  end

  def test_exist_returns_true_if_key_exists
    WorkOS::Cache.write("key", "value")
    assert_equal true, WorkOS::Cache.exist?("key")
  end

  def test_exist_returns_false_if_expired
    WorkOS::Cache.write("key", "value", expires_in: 0.1)
    sleep 0.2
    assert_equal false, WorkOS::Cache.exist?("key")
  end

  def test_exist_returns_false_if_key_does_not_exist
    assert_equal false, WorkOS::Cache.exist?("missing")
  end

  def test_delete_removes_key
    WorkOS::Cache.write("key", "value")
    WorkOS::Cache.delete("key")
    assert_nil WorkOS::Cache.read("key")
  end

  def test_clear_removes_all_keys
    WorkOS::Cache.write("key1", "value1")
    WorkOS::Cache.write("key2", "value2")

    WorkOS::Cache.clear

    assert_nil WorkOS::Cache.read("key1")
    assert_nil WorkOS::Cache.read("key2")
  end
end
