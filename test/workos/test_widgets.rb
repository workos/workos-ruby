# frozen_string_literal: true

require "test_helper"

class TestWidgets < WorkOS::TestCase
  def setup
    super
    @organization_id = "org_01JCP9G67MNAH0KC4B72XZ67M7"
    @user_id = "user_01JCP9H4SHS4N3J6XTKDT7JNPE"
  end

  def test_get_token_with_valid_params
    VCR.use_cassette "widgets/get_token" do
      token = WorkOS::Widgets.get_token(
        organization_id: @organization_id,
        user_id: @user_id,
        scopes: ["widgets:users-table:manage"]
      )

      assert token.start_with?("eyJhbGciOiJSUzI1NiIsImtpZ")
    end
  end

  def test_get_token_with_invalid_organization_id
    VCR.use_cassette "widgets/get_token_invalid_organization_id" do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::Widgets.get_token(
          organization_id: "bogus-id",
          user_id: @user_id,
          scopes: ["widgets:users-table:manage"]
        )
      end
      assert_match(/Organization not found: 'bogus-id'/, err.message)
    end
  end

  def test_get_token_with_invalid_user_id
    VCR.use_cassette "widgets/get_token_invalid_user_id" do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::Widgets.get_token(
          organization_id: @organization_id,
          user_id: "bogus-id",
          scopes: ["widgets:users-table:manage"]
        )
      end
      assert_match(/User not found: 'bogus-id'/, err.message)
    end
  end

  def test_get_token_with_invalid_scopes
    err = assert_raises(ArgumentError) do
      WorkOS::Widgets.get_token(
        organization_id: @organization_id,
        user_id: @user_id,
        scopes: ["bogus-scope"]
      )
    end
    assert_match(/scopes contains an invalid value/, err.message)
  end
end
