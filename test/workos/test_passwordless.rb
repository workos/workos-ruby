# frozen_string_literal: true

require "test_helper"

class TestPasswordless < WorkOS::TestCase
  def test_create_session_with_valid_options
    VCR.use_cassette("passwordless/create_session") do
      response = WorkOS::Passwordless.create_session(
        email: "demo@workos-okta.com",
        type: "MagicLink",
        redirect_uri: "foo.com/auth/callback"
      )

      assert_equal "demo@workos-okta.com", response.email
    end
  end

  def test_create_session_with_invalid_options
    VCR.use_cassette("passwordless/create_session_invalid") do
      err = assert_raises(WorkOS::UnprocessableEntityError) do
        WorkOS::Passwordless.create_session({})
      end
      assert_match(
        /Status 422, Validation failed \(email: email must be a string; type: type must be a valid enum value\)/,
        err.message
      )
    end
  end

  def test_send_session_with_valid_session_id
    VCR.use_cassette("passwordless/send_session") do
      response = WorkOS::Passwordless.send_session(
        "passwordless_session_01EJC0F4KH42T11Y2DHPEB09BM"
      )

      assert_equal true, response["success"]
    end
  end

  def test_send_session_with_invalid_session_id
    VCR.use_cassette("passwordless/send_session_invalid") do
      err = assert_raises(WorkOS::UnprocessableEntityError) do
        WorkOS::Passwordless.send_session("session_123")
      end
      assert_match(
        /Status 422, The passwordless session 'session_123' has expired or is invalid./,
        err.message
      )
    end
  end
end
