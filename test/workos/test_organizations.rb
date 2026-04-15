# frozen_string_literal: true

require "test_helper"

class TestOrganizations < WorkOS::TestCase
  def test_create_organization
    VCR.use_cassette "organization/create" do
      organization = WorkOS::Organizations.create_organization(
        domains: ["example.io"],
        name: "Test Organization"
      )

      assert_equal "org_01FCPEJXEZR4DSBA625YMGQT9N", organization.id
      assert_equal "Test Organization", organization.name
      assert_equal "example.io", organization.domains.first[:domain]
    end
  end

  def test_create_organization_without_domains
    VCR.use_cassette "organization/create_without_domains" do
      organization = WorkOS::Organizations.create_organization(
        name: "Test Organization"
      )

      assert organization.id.start_with?("org_")
      assert_equal "Test Organization", organization.name
      assert organization.domains.empty?
    end
  end

  def test_create_organization_with_external_id
    VCR.use_cassette "organization/create_with_external_id" do
      organization = WorkOS::Organizations.create_organization(
        name: "Test Organization with External ID",
        external_id: "ext_org_123"
      )

      assert organization.id.start_with?("org_")
      assert_equal "Test Organization with External ID", organization.name
      assert_equal "ext_org_123", organization.external_id
    end
  end

  def test_create_organization_with_domains_warns_deprecation
    VCR.use_cassette "organization/create_with_domains" do
      _, err = capture_io do
        organization = WorkOS::Organizations.create_organization(
          domains: ["example.io"],
          name: "Test Organization"
        )

        assert organization.id.start_with?("org_")
        assert_equal "Test Organization", organization.name
        assert_equal "example.io", organization.domains.first[:domain]
      end
      assert_match(/\[DEPRECATION\] `domains` is deprecated. Use `domain_data` instead./, err)
    end
  end

  def test_create_organization_with_domain_data
    VCR.use_cassette "organization/create_with_domain_data" do
      organization = WorkOS::Organizations.create_organization(
        domain_data: [{domain: "example.io", state: "verified"}],
        name: "Test Organization"
      )

      assert organization.id.start_with?("org_")
      assert_equal "Test Organization", organization.name
      assert_equal "example.io", organization.domains.first[:domain]
      assert_equal "verified", organization.domains.first[:state]
    end
  end

  def test_create_organization_with_idempotency_key
    VCR.use_cassette "organization/create_with_idempotency_key" do
      organization = WorkOS::Organizations.create_organization(
        domains: ["example.io"],
        name: "Test Organization",
        idempotency_key: "key"
      )

      assert_equal "Test Organization", organization.name
      assert_equal "example.io", organization.domains.first[:domain]
    end
  end

  def test_create_organization_with_duplicate_idempotency_key_and_payload
    VCR.use_cassette "organization/create_with_duplicate_idempotency_key_and_payload" do
      organization1 = WorkOS::Organizations.create_organization(
        domains: ["example.com"],
        name: "Test Organization",
        idempotency_key: "foo"
      )

      organization2 = WorkOS::Organizations.create_organization(
        domains: ["example.com"],
        name: "Test Organization",
        idempotency_key: "foo"
      )

      assert_equal organization1.id, organization2.id
    end
  end

  def test_create_organization_with_duplicate_idempotency_key_and_different_payload
    VCR.use_cassette "organization/create_with_duplicate_idempotency_key_and_different_payload" do
      WorkOS::Organizations.create_organization(
        domains: ["example.me"],
        name: "Test Organization",
        idempotency_key: "bar"
      )

      err = assert_raises(WorkOS::InvalidRequestError) do
        WorkOS::Organizations.create_organization(
          domains: ["example.me"],
          name: "Organization Test",
          idempotency_key: "bar"
        )
      end
      assert_match(/Status 400, Another idempotency key \(bar\) with different request parameters was found. Please use a different idempotency key./, err.message)
    end
  end

  def test_create_organization_with_invalid_payload
    VCR.use_cassette "organization/create_invalid" do
      err = assert_raises(WorkOS::APIError) do
        WorkOS::Organizations.create_organization(
          domains: ["example.com"],
          name: "Test Organization 2"
        )
      end
      assert_match(/An Organization with the domain example.com already exists/, err.message)
    end
  end

  def test_list_organizations_with_no_options
    expected_metadata = {
      "after" => nil,
      "before" => "before-id"
    }

    VCR.use_cassette "organization/list" do
      organizations = WorkOS::Organizations.list_organizations

      assert_equal 6, organizations.data.size
      assert_equal expected_metadata, organizations.list_metadata
    end
  end

  def test_list_organizations_with_before
    VCR.use_cassette "organization/list", match_requests_on: [:path] do
      organizations = WorkOS::Organizations.list_organizations(
        before: "before-id"
      )

      assert_equal 6, organizations.data.size
    end
  end

  def test_list_organizations_with_after
    VCR.use_cassette "organization/list", match_requests_on: [:path] do
      organizations = WorkOS::Organizations.list_organizations(after: "after-id")

      assert_equal 6, organizations.data.size
    end
  end

  def test_list_organizations_with_limit
    VCR.use_cassette "organization/list", match_requests_on: [:path] do
      organizations = WorkOS::Organizations.list_organizations(limit: 10)

      assert_equal 6, organizations.data.size
    end
  end

  def test_get_organization_with_valid_id
    VCR.use_cassette("organization/get") do
      organization = WorkOS::Organizations.get_organization(
        id: "org_01F9293WD2PDEEV4Y625XPZVG7"
      )

      assert_equal "org_01F9293WD2PDEEV4Y625XPZVG7", organization.id
      assert_equal "Foo Corp", organization.name
      assert_equal "foo-corp.com", organization.domains.first[:domain]
    end
  end

  def test_get_organization_with_invalid_id
    VCR.use_cassette("organization/get_invalid") do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::Organizations.get_organization(id: "invalid")
      end
      assert_equal "Status 404, Not Found - request ID: ", err.message
    end
  end

  def test_update_organization
    VCR.use_cassette "organization/update" do
      organization = WorkOS::Organizations.update_organization(
        organization: "org_01F6Q6TFP7RD2PF6J03ANNWDKV",
        domains: ["example.me"],
        name: "Test Organization"
      )

      assert_equal "org_01F6Q6TFP7RD2PF6J03ANNWDKV", organization.id
      assert_equal "Test Organization", organization.name
      assert_equal "example.me", organization.domains.first[:domain]
    end
  end

  def test_update_organization_without_name
    VCR.use_cassette "organization/update_without_name" do
      organization = WorkOS::Organizations.update_organization(
        organization: "org_01F6Q6TFP7RD2PF6J03ANNWDKV",
        domains: ["example.me"]
      )

      assert_equal "org_01F6Q6TFP7RD2PF6J03ANNWDKV", organization.id
      assert_equal "Test Organization", organization.name
      assert_equal "example.me", organization.domains.first[:domain]
    end
  end

  def test_update_organization_with_stripe_customer_id
    VCR.use_cassette "organization/update_with_stripe_customer_id" do
      organization = WorkOS::Organizations.update_organization(
        organization: "org_01JJ5H14CAA2SQ5G9HNN6TBZ05",
        name: "Test Organization",
        stripe_customer_id: "cus_123"
      )

      assert_equal "org_01JJ5H14CAA2SQ5G9HNN6TBZ05", organization.id
      assert_equal "Test Organization", organization.name
      assert_equal "cus_123", organization.stripe_customer_id
    end
  end

  def test_update_organization_with_external_id
    VCR.use_cassette "organization/update_with_external_id" do
      organization = WorkOS::Organizations.update_organization(
        organization: "org_01K0SQV0S6EPWK2ZDEFD1CP1JC",
        name: "Test Organization",
        external_id: "ext_org_456"
      )

      assert_equal "org_01K0SQV0S6EPWK2ZDEFD1CP1JC", organization.id
      assert_equal "Test Organization", organization.name
      assert_equal "ext_org_456", organization.external_id
    end
  end

  def test_update_organization_with_external_id_null
    VCR.use_cassette "organization/update_with_external_id_null" do
      organization = WorkOS::Organizations.update_organization(
        organization: "org_01K0SQV0S6EPWK2ZDEFD1CP1JC",
        name: "Test Organization",
        external_id: nil
      )

      assert_nil organization.external_id
    end
  end

  def test_delete_organization_with_valid_id
    VCR.use_cassette("organization/delete") do
      response = WorkOS::Organizations.delete_organization(
        id: "org_01F4A8TD0B4N1Y9SJ8SH635HDB"
      )

      assert_equal true, response
    end
  end

  def test_delete_organization_with_invalid_id
    VCR.use_cassette("organization/delete_invalid") do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::Organizations.delete_organization(id: "invalid")
      end
      assert_equal "Status 404, Not Found - request ID: ", err.message
    end
  end

  def test_list_organization_roles
    expected_metadata = {
      after: nil,
      before: nil
    }

    VCR.use_cassette "organization/list_organization_roles" do
      roles = WorkOS::Organizations.list_organization_roles(
        organization_id: "org_01JEXP6Z3X7HE4CB6WQSH9ZAFE"
      )

      assert_equal 7, roles.data.size
      assert_equal expected_metadata, roles.list_metadata
    end
  end

  def test_list_organization_roles_returns_properly_initialized_role_objects
    VCR.use_cassette "organization/list_organization_roles" do
      roles = WorkOS::Organizations.list_organization_roles(
        organization_id: "org_01JEXP6Z3X7HE4CB6WQSH9ZAFE"
      )

      first_role = roles.data.first
      assert_kind_of WorkOS::Role, first_role
      assert_equal "role_01HS1C7GRJE08PBR3M6Y0ZYGDZ", first_role.id
      assert_equal "Admin", first_role.name
      assert_equal "admin", first_role.slug
      assert_equal "Write access to every resource available", first_role.description
      assert_equal ["admin:all", "read:users", "write:users", "manage:roles"], first_role.permissions
      assert_equal "EnvironmentRole", first_role.type
      assert_equal "2024-03-15T15:38:29.521Z", first_role.created_at
      assert_equal "2024-11-14T17:08:00.556Z", first_role.updated_at
    end
  end

  def test_list_organization_roles_handles_empty_permissions
    VCR.use_cassette "organization/list_organization_roles" do
      roles = WorkOS::Organizations.list_organization_roles(
        organization_id: "org_01JEXP6Z3X7HE4CB6WQSH9ZAFE"
      )

      platform_manager_role = roles.data.find { |role| role.slug == "org-platform-manager" }
      assert_kind_of WorkOS::Role, platform_manager_role
      assert_equal [], platform_manager_role.permissions
    end
  end

  def test_list_organization_roles_serializes_including_permissions
    VCR.use_cassette "organization/list_organization_roles" do
      roles = WorkOS::Organizations.list_organization_roles(
        organization_id: "org_01JEXP6Z3X7HE4CB6WQSH9ZAFE"
      )

      billing_role = roles.data.find { |role| role.slug == "billing" }
      serialized = billing_role.to_json

      assert_equal "role_01JA8GJZRDSZEB9289DQXJ3N9Z", serialized[:id]
      assert_equal "Billing Manager", serialized[:name]
      assert_equal "billing", serialized[:slug]
      assert_equal ["read:billing", "write:billing"], serialized[:permissions]
      assert_equal "EnvironmentRole", serialized[:type]
    end
  end

  def test_list_organization_feature_flags
    expected_metadata = {
      after: nil,
      before: nil
    }

    VCR.use_cassette "organization/list_organization_feature_flags" do
      feature_flags = WorkOS::Organizations.list_organization_feature_flags(
        organization_id: "org_01HX7Q7R12H1JMAKN75SH2G529"
      )

      assert_equal 2, feature_flags.data.size
      assert_equal expected_metadata, feature_flags.list_metadata
    end
  end

  def test_list_organization_feature_flags_with_before
    VCR.use_cassette "organization/list_organization_feature_flags", match_requests_on: [:path] do
      feature_flags = WorkOS::Organizations.list_organization_feature_flags(
        organization_id: "org_01HX7Q7R12H1JMAKN75SH2G529",
        options: {before: "before-id"}
      )

      assert_equal 2, feature_flags.data.size
    end
  end

  def test_list_organization_feature_flags_with_after
    VCR.use_cassette "organization/list_organization_feature_flags", match_requests_on: [:path] do
      feature_flags = WorkOS::Organizations.list_organization_feature_flags(
        organization_id: "org_01HX7Q7R12H1JMAKN75SH2G529",
        options: {after: "after-id"}
      )

      assert_equal 2, feature_flags.data.size
    end
  end

  def test_list_organization_feature_flags_with_limit
    VCR.use_cassette "organization/list_organization_feature_flags", match_requests_on: [:path] do
      feature_flags = WorkOS::Organizations.list_organization_feature_flags(
        organization_id: "org_01HX7Q7R12H1JMAKN75SH2G529",
        options: {limit: 10}
      )

      assert_equal 2, feature_flags.data.size
    end
  end

  def test_list_organization_feature_flags_with_multiple_pagination_options
    VCR.use_cassette "organization/list_organization_feature_flags", match_requests_on: [:path] do
      feature_flags = WorkOS::Organizations.list_organization_feature_flags(
        organization_id: "org_01HX7Q7R12H1JMAKN75SH2G529",
        options: {after: "after-id", limit: 5, order: "asc"}
      )

      assert_equal 2, feature_flags.data.size
    end
  end
end
