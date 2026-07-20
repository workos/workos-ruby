# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained runtime

require "test_helper"

class NullTest < Minitest::Test
  def setup
    @client = WorkOS::Client.new(api_key: "sk_test_123")
  end

  def test_null_serializes_as_json_null
    assert_equal "null", WorkOS::Null.to_json
    assert_nil WorkOS::Null.as_json
    assert_equal "WorkOS::Null", WorkOS::Null.inspect
  end

  def test_nil_param_is_omitted_from_request_body
    request = stub_request(:put, "https://api.workos.com/organizations/org_123")
      .with { |req| !JSON.parse(req.body).key?("external_id") }
      .to_return(body: "{}", status: 200)

    @client.organizations.update_organization(id: "org_123", external_id: nil)

    assert_requested(request)
  end

  def test_null_param_clears_field_via_explicit_null
    request = stub_request(:put, "https://api.workos.com/organizations/org_123")
      .with { |req| JSON.parse(req.body) == {"external_id" => nil} }
      .to_return(body: "{}", status: 200)

    @client.organizations.update_organization(id: "org_123", external_id: WorkOS::Null)

    assert_requested(request)
  end

  def test_null_param_clears_user_external_id
    request = stub_request(:put, "https://api.workos.com/user_management/users/user_123")
      .with { |req| JSON.parse(req.body) == {"external_id" => nil} }
      .to_return(body: "{}", status: 200)

    @client.user_management.update_user(id: "user_123", external_id: WorkOS::Null)

    assert_requested(request)
  end

  def test_null_works_through_raw_request_helper
    request = stub_request(:put, "https://api.workos.com/organizations/org_123")
      .with { |req| JSON.parse(req.body) == {"external_id" => nil} }
      .to_return(body: "{}", status: 200)

    @client.request(method: :put, path: "/organizations/org_123", body: {"external_id" => WorkOS::Null})

    assert_requested(request)
  end

  def test_null_nested_in_hash_serializes_as_null
    request = stub_request(:put, "https://api.workos.com/organizations/org_123")
      .with { |req| JSON.parse(req.body) == {"metadata" => {"tier" => nil, "plan" => "pro"}} }
      .to_return(body: "{}", status: 200)

    @client.request(
      method: :put,
      path: "/organizations/org_123",
      body: {"metadata" => {"tier" => WorkOS::Null, "plan" => "pro"}}
    )

    assert_requested(request)
  end
end
