# frozen_string_literal: true

require "test_helper"

class TestClient < WorkOS::TestCase
  def test_returns_400_error_with_appropriate_fields
    VCR.use_cassette("user_management/authenticate_with_code/invalid") do
      error = assert_raises(WorkOS::InvalidRequestError) do
        WorkOS::UserManagement.authenticate_with_code(
          code: "invalid",
          client_id: "client_123",
          ip_address: "200.240.210.16",
          user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36"
        )
      end

      refute_nil error.error
      refute_nil error.error_description
      refute_nil error.data
    end
  end

  def test_returns_401_error_with_appropriate_fields
    VCR.use_cassette("base/execute_request_unauthenticated") do
      error = assert_raises(WorkOS::AuthenticationError) do
        WorkOS::AuditLogs.create_event(
          organization: "org_123",
          event: {}
        )
      end

      refute_nil error.message
    end
  end

  def test_returns_404_error_with_appropriate_fields
    VCR.use_cassette("user_management/get_email_verification/invalid") do
      error = assert_raises(WorkOS::NotFoundError) do
        WorkOS::UserManagement.get_email_verification(
          id: "invalid"
        )
      end

      refute_nil error.message
    end
  end

  def test_returns_422_error_with_appropriate_fields
    VCR.use_cassette("user_management/create_user_invalid") do
      error = assert_raises(WorkOS::UnprocessableEntityError) do
        WorkOS::UserManagement.create_user(
          email: "invalid"
        )
      end

      refute_nil error.message
      refute_nil error.errors
      refute_nil error.code
    end
  end
end
