# frozen_string_literal: true

require "test_helper"

# Verifies the oagen-generated "explicit null clears a nullable field" behavior:
#   - omitting a nullable argument leaves the field out of the request body
#   - passing an explicit `nil` sends JSON `null` (clearing the field)
#   - passing a concrete value sends that value
class NullableClearingTest < Minitest::Test
  def setup
    @client = WorkOS::Client.new(api_key: "sk_test_123")
  end

  def captured_body(verb, url)
    body = nil
    stub_request(verb, url)
      .with { |req|
        body = req.body
        true
      }
      .to_return(body: "{}", status: 200)
    yield
    JSON.parse(body)
  end

  def test_omitted_nullable_field_is_not_sent
    url = %r{\Ahttps://api\.workos\.com/organizations/org_123(\?|\z)}
    body = captured_body(:put, url) do
      @client.organizations.update_organization(id: "org_123", name: "New Name")
    end
    refute body.key?("external_id"), "omitted external_id should not be in the body"
    assert_equal "New Name", body["name"]
  end

  def test_explicit_nil_clears_nullable_field
    url = %r{\Ahttps://api\.workos\.com/organizations/org_123(\?|\z)}
    body = captured_body(:put, url) do
      @client.organizations.update_organization(id: "org_123", external_id: nil)
    end
    assert body.key?("external_id"), "explicit nil external_id should be in the body"
    assert_nil body["external_id"], "explicit nil external_id should serialize as JSON null"
  end

  def test_concrete_value_is_sent
    url = %r{\Ahttps://api\.workos\.com/organizations/org_123(\?|\z)}
    body = captured_body(:put, url) do
      @client.organizations.update_organization(id: "org_123", external_id: "ext-123")
    end
    assert_equal "ext-123", body["external_id"]
  end

  def test_user_explicit_nil_clears_external_id
    url = %r{\Ahttps://api\.workos\.com/user_management/users/user_123(\?|\z)}
    body = captured_body(:put, url) do
      @client.user_management.update_user(id: "user_123", external_id: nil)
    end
    assert body.key?("external_id"), "explicit nil external_id should be in the body"
    assert_nil body["external_id"]
  end

  def test_user_omitted_external_id_is_not_sent
    url = %r{\Ahttps://api\.workos\.com/user_management/users/user_123(\?|\z)}
    body = captured_body(:put, url) do
      @client.user_management.update_user(id: "user_123", first_name: "Ada")
    end
    refute body.key?("external_id")
    assert_equal "Ada", body["first_name"]
  end
end
