# frozen_string_literal: true

require "test_helper"

class TestPortal < WorkOS::TestCase
  def setup
    super
    @organization = "org_01EHQMYV6MBK39QC5PZXHY59C3"
  end

  def test_generate_link_with_sso_intent
    VCR.use_cassette "portal/generate_link_sso" do
      portal_link = WorkOS::Portal.generate_link(
        intent: "sso",
        organization: @organization
      )

      assert_equal "https://id.workos.com/portal/launch?secret=secret", portal_link
    end
  end

  def test_generate_link_with_dsync_intent
    VCR.use_cassette "portal/generate_link_dsync" do
      portal_link = WorkOS::Portal.generate_link(
        intent: "dsync",
        organization: @organization
      )

      assert_equal "https://id.workos.com/portal/launch?secret=secret", portal_link
    end
  end

  def test_generate_link_with_audit_logs_intent
    VCR.use_cassette "portal/generate_link_audit_logs", match_requests_on: %i[path body] do
      portal_link = WorkOS::Portal.generate_link(
        intent: "audit_logs",
        organization: @organization
      )

      assert_equal "https://id.workos.com/portal/launch?secret=secret", portal_link
    end
  end

  def test_generate_link_with_certificate_renewal_intent
    VCR.use_cassette "portal/generate_link_certificate_renewal", match_requests_on: %i[path body] do
      portal_link = WorkOS::Portal.generate_link(
        intent: "certificate_renewal",
        organization: @organization
      )

      assert_equal "https://id.workos.com/portal/launch?secret=secret", portal_link
    end
  end

  def test_generate_link_with_domain_verification_intent
    VCR.use_cassette "portal/generate_link_domain_verification", match_requests_on: %i[path body] do
      portal_link = WorkOS::Portal.generate_link(
        intent: "domain_verification",
        organization: @organization
      )

      assert_equal "https://id.workos.com/portal/launch?secret=secret", portal_link
    end
  end

  def test_generate_link_with_invalid_organization
    VCR.use_cassette "portal/generate_link_invalid" do
      err = assert_raises(WorkOS::InvalidRequestError) do
        WorkOS::Portal.generate_link(
          intent: "sso",
          organization: "bogus-id"
        )
      end
      assert_match(/Could not find an organization with the id, bogus-id/, err.message)
    end
  end

  def test_generate_link_with_invalid_intent
    err = assert_raises(ArgumentError) do
      WorkOS::Portal.generate_link(
        intent: "bogus-intent",
        organization: @organization
      )
    end
    assert_match(/bogus-intent is not a valid value/, err.message)
  end
end
