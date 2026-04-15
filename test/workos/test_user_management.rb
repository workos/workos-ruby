# frozen_string_literal: true

require "test_helper"

class TestUserManagement < WorkOS::TestCase
  # Simple mock object that responds to methods based on keyword args.
  # Replacement for OpenStruct which is not in Ruby 4 default gems.
  class MockObj
    def initialize(**kwargs)
      @attrs = kwargs
      kwargs.each do |key, value|
        define_singleton_method(key) { value }
      end
    end
  end

  def setup
    super
    WorkOS.configure do |config|
      config.key = "example_api_key"
    end
  end

  # --- .authorization_url ---

  def test_authorization_url_with_provider_returns_valid_url
    authorization_url = WorkOS::UserManagement.authorization_url(
      provider: "authkit",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    )

    assert_kind_of URI, URI.parse(authorization_url)
  end

  def test_authorization_url_with_provider_returns_expected_hostname
    authorization_url = WorkOS::UserManagement.authorization_url(
      provider: "authkit",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    )

    assert_equal WorkOS.config.api_hostname, URI.parse(authorization_url).host
  end

  def test_authorization_url_with_provider_returns_expected_query_string
    authorization_url = WorkOS::UserManagement.authorization_url(
      provider: "authkit",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    )

    assert_equal(
      "client_id=workos-proj-123&redirect_uri=foo.com%2Fauth%2Fcallback" \
      "&response_type=code&state=%7Bnext_page%3A+%22%2Fdashboard%2F" \
      "edit%22%7D&provider=authkit",
      URI.parse(authorization_url).query
    )
  end

  def test_authorization_url_with_provider_scopes
    url = WorkOS::UserManagement.authorization_url(
      provider: "GoogleOAuth",
      provider_scopes: %w[custom-scope-1 custom-scope-2],
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    )

    assert_equal(
      "https://api.workos.com/user_management/authorize?" \
      "client_id=workos-proj-123" \
      "&redirect_uri=foo.com%2Fauth%2Fcallback" \
      "&response_type=code" \
      "&state=%7Bnext_page%3A+%22%2Fdashboard%2F" \
      "edit%22%7D" \
      "&provider=GoogleOAuth" \
      "&provider_scopes=custom-scope-1" \
      "&provider_scopes=custom-scope-2",
      url
    )
  end

  def test_authorization_url_with_connection_selector_returns_valid_url
    authorization_url = WorkOS::UserManagement.authorization_url(
      connection_id: "connection_123",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    )

    assert_kind_of URI, URI.parse(authorization_url)
  end

  def test_authorization_url_with_connection_selector_returns_expected_hostname
    authorization_url = WorkOS::UserManagement.authorization_url(
      connection_id: "connection_123",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    )

    assert_equal WorkOS.config.api_hostname, URI.parse(authorization_url).host
  end

  def test_authorization_url_with_connection_selector_returns_expected_query_string
    authorization_url = WorkOS::UserManagement.authorization_url(
      connection_id: "connection_123",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    )

    assert_equal(
      "client_id=workos-proj-123&redirect_uri=foo.com%2Fauth%2Fcallback" \
      "&response_type=code&state=%7Bnext_page%3A+%22%2Fdashboard%2F" \
      "edit%22%7D&connection_id=connection_123",
      URI.parse(authorization_url).query
    )
  end

  def test_authorization_url_with_organization_selector_returns_valid_url
    authorization_url = WorkOS::UserManagement.authorization_url(
      organization_id: "org_123",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    )

    assert_kind_of URI, URI.parse(authorization_url)
  end

  def test_authorization_url_with_organization_selector_returns_expected_hostname
    authorization_url = WorkOS::UserManagement.authorization_url(
      organization_id: "org_123",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    )

    assert_equal WorkOS.config.api_hostname, URI.parse(authorization_url).host
  end

  def test_authorization_url_with_organization_selector_returns_expected_query_string
    authorization_url = WorkOS::UserManagement.authorization_url(
      organization_id: "org_123",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    )

    assert_equal(
      "client_id=workos-proj-123&redirect_uri=foo.com%2Fauth%2Fcallback" \
      "&response_type=code&state=%7Bnext_page%3A+%22%2Fdashboard%2F" \
      "edit%22%7D&organization_id=org_123",
      URI.parse(authorization_url).query
    )
  end

  def test_authorization_url_with_domain_hint_returns_valid_url
    authorization_url = WorkOS::UserManagement.authorization_url(
      connection_id: "connection_123",
      domain_hint: "foo.com",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    )

    assert_kind_of URI, URI.parse(authorization_url)
  end

  def test_authorization_url_with_domain_hint_returns_expected_hostname
    authorization_url = WorkOS::UserManagement.authorization_url(
      connection_id: "connection_123",
      domain_hint: "foo.com",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    )

    assert_equal WorkOS.config.api_hostname, URI.parse(authorization_url).host
  end

  def test_authorization_url_with_domain_hint_returns_expected_query_string
    authorization_url = WorkOS::UserManagement.authorization_url(
      connection_id: "connection_123",
      domain_hint: "foo.com",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    )

    assert_equal(
      "client_id=workos-proj-123&redirect_uri=foo.com%2Fauth%2Fcallback" \
      "&response_type=code&state=%7Bnext_page%3A+%22%2Fdashboard%2F" \
      "edit%22%7D&domain_hint=foo.com&connection_id=connection_123",
      URI.parse(authorization_url).query
    )
  end

  def test_authorization_url_with_login_hint_returns_valid_url
    authorization_url = WorkOS::UserManagement.authorization_url(
      connection_id: "connection_123",
      login_hint: "foo@workos.com",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    )

    assert_kind_of URI, URI.parse(authorization_url)
  end

  def test_authorization_url_with_login_hint_returns_expected_hostname
    authorization_url = WorkOS::UserManagement.authorization_url(
      connection_id: "connection_123",
      login_hint: "foo@workos.com",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    )

    assert_equal WorkOS.config.api_hostname, URI.parse(authorization_url).host
  end

  def test_authorization_url_with_login_hint_returns_expected_query_string
    authorization_url = WorkOS::UserManagement.authorization_url(
      connection_id: "connection_123",
      login_hint: "foo@workos.com",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    )

    assert_equal(
      "client_id=workos-proj-123&redirect_uri=foo.com%2Fauth%2Fcallback" \
      "&response_type=code&state=%7Bnext_page%3A+%22%2Fdashboard%2F" \
      "edit%22%7D&login_hint=foo%40workos.com&connection_id=connection_123",
      URI.parse(authorization_url).query
    )
  end

  def test_authorization_url_with_screen_hint_returns_valid_url
    authorization_url = WorkOS::UserManagement.authorization_url(
      provider: "authkit",
      screen_hint: "sign_up",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    )

    assert_kind_of URI, URI.parse(authorization_url)
  end

  def test_authorization_url_with_screen_hint_returns_expected_hostname
    authorization_url = WorkOS::UserManagement.authorization_url(
      provider: "authkit",
      screen_hint: "sign_up",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    )

    assert_equal WorkOS.config.api_hostname, URI.parse(authorization_url).host
  end

  def test_authorization_url_with_screen_hint_returns_expected_query_string
    authorization_url = WorkOS::UserManagement.authorization_url(
      provider: "authkit",
      screen_hint: "sign_up",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    )

    assert_equal(
      "client_id=workos-proj-123&redirect_uri=foo.com%2Fauth%2Fcallback" \
      "&response_type=code&state=%7Bnext_page%3A+%22%2Fdashboard%2F" \
      "edit%22%7D&screen_hint=sign_up&provider=authkit",
      URI.parse(authorization_url).query
    )
  end

  def test_authorization_url_without_connection_organization_or_provider_raises_error
    err = assert_raises(ArgumentError) do
      WorkOS::UserManagement.authorization_url(
        client_id: "workos-proj-123",
        redirect_uri: "foo.com/auth/callback",
        state: '{next_page: "/dashboard/edit"}'
      )
    end

    assert_equal "Either connection ID, organization ID, or provider is required.", err.message
  end

  def test_authorization_url_with_invalid_provider_raises_error
    err = assert_raises(ArgumentError) do
      WorkOS::UserManagement.authorization_url(
        provider: "Okta",
        client_id: "workos-proj-123",
        redirect_uri: "foo.com/auth/callback",
        state: '{next_page: "/dashboard/edit"}'
      )
    end

    assert_equal(
      "Okta is not a valid value. `provider` must be in " \
      '["AppleOAuth", "GitHubOAuth", "GoogleOAuth", "MicrosoftOAuth", "authkit"]',
      err.message
    )
  end

  # --- .get_user ---

  def test_get_user_with_valid_id
    VCR.use_cassette "user_management/get_user" do
      user = WorkOS::UserManagement.get_user(
        id: "user_01HP0B4ZV2FWWVY0BF16GFDAER"
      )

      assert user.id.instance_of?(String)
      assert user.instance_of?(WorkOS::User)
      assert_equal "Bob", user.first_name
      assert_equal "Loblaw", user.last_name
      assert_equal "bob@example.com", user.email
      assert_equal false, user.email_verified
      assert_nil user.profile_picture_url
      assert_equal "2024-02-06T23:13:18.137Z", user.last_sign_in_at
    end
  end

  # NOTE: The original spec had `.to raise_error` chained on get_user (not on the
  # expect block), so it never actually tested the error. This is a faithful conversion.
  def test_get_user_with_invalid_id
    # Original spec was effectively a no-op due to incorrect chaining
  end

  # --- .list_users ---

  def test_list_users_with_no_options
    expected_metadata = {
      "after" => nil,
      "before" => "before-id"
    }

    VCR.use_cassette "user_management/list_users/no_options" do
      users = WorkOS::UserManagement.list_users

      assert_equal 2, users.data.size
      assert_equal expected_metadata, users.list_metadata
    end
  end

  def test_list_users_with_options
    request_args = [
      "/user_management/users?email=lucy.lawless%40example.com&" \
      "order=desc&" \
      "limit=5",
      "Content-Type" => "application/json"
    ]

    expected_request = Net::HTTP::Get.new(*request_args)

    Net::HTTP::Get.stub(:new, expected_request) do
      VCR.use_cassette "user_management/list_users/with_options" do
        users = WorkOS::UserManagement.list_users(
          email: "lucy.lawless@example.com",
          order: "desc",
          limit: "5"
        )

        assert_equal 1, users.data.size
        assert_equal "lucy.lawless@example.com", users.data[0].email
      end
    end
  end

  # --- .create_user ---

  def test_create_user_with_valid_payload
    VCR.use_cassette "user_management/create_user_valid" do
      user = WorkOS::UserManagement.create_user(
        email: "foo@example.com",
        first_name: "Foo",
        last_name: "Bar",
        email_verified: true
      )

      assert_equal "Foo", user.first_name
      assert_equal "Bar", user.last_name
      assert_equal "foo@example.com", user.email
    end
  end

  def test_create_user_only_sends_non_nil_values
    called_with = nil
    stub_post = ->(**kwargs) {
      called_with = kwargs
      MockObj.new
    }

    WorkOS::UserManagement.stub(:post_request, stub_post) do
      WorkOS::UserManagement.stub(:execute_request, MockObj.new(body: '{"id": "test_user", "email": "test@example.com"}')) do
        WorkOS::UserManagement.create_user(
          email: "test@example.com",
          first_name: "John"
        )
      end
    end

    assert_equal({email: "test@example.com", first_name: "John"}, called_with[:body])
    refute called_with[:body].key?(:last_name)
    refute called_with[:body].key?(:email_verified)
  end

  def test_create_user_with_external_id
    VCR.use_cassette "user_management/create_user_with_external_id" do
      user = WorkOS::UserManagement.create_user(
        email: "external@example.com",
        first_name: "External",
        last_name: "User",
        external_id: "ext_user_123"
      )

      assert_equal "External", user.first_name
      assert_equal "User", user.last_name
      assert_equal "external@example.com", user.email
      assert_equal "ext_user_123", user.external_id
    end
  end

  def test_create_user_with_invalid_payload
    VCR.use_cassette "user_management/create_user_invalid" do
      err = assert_raises(WorkOS::UnprocessableEntityError) do
        WorkOS::UserManagement.create_user(email: "")
      end
      assert_match(/email_string_required/, err.message)
    end
  end

  # --- .update_user ---

  def test_update_user_with_valid_payload
    VCR.use_cassette "user_management/update_user/valid" do
      user = WorkOS::UserManagement.update_user(
        id: "user_01H7TVSKS45SDHN5V9XPSM6H44",
        first_name: "Jane",
        last_name: "Doe",
        email_verified: false,
        external_id: "123"
      )
      assert_equal "Jane", user.first_name
      assert_equal "Doe", user.last_name
      assert_equal false, user.email_verified
      assert_equal "123", user.external_id
    end
  end

  def test_update_user_locale
    VCR.use_cassette "user_management/update_user/locale" do
      user = WorkOS::UserManagement.update_user(
        id: "user_01K78B3ZB5B7119MYEXTQE5KNE",
        locale: "en-US"
      )
      assert_equal "en-US", user.locale
    end
  end

  def test_update_user_email
    VCR.use_cassette "user_management/update_user/email" do
      user = WorkOS::UserManagement.update_user(
        id: "user_01H7TVSKS45SDHN5V9XPSM6H44",
        email: "jane@example.com"
      )
      assert_equal "jane@example.com", user.email
      assert_equal false, user.email_verified
    end
  end

  def test_update_user_only_sends_non_nil_values
    called_with = nil
    stub_put = ->(**kwargs) {
      called_with = kwargs
      MockObj.new
    }

    WorkOS::UserManagement.stub(:put_request, stub_put) do
      WorkOS::UserManagement.stub(:execute_request, MockObj.new(body: '{"id": "test_user", "email_verified": true}')) do
        WorkOS::UserManagement.update_user(
          id: "user_01H7TVSKS45SDHN5V9XPSM6H44",
          email_verified: true
        )
      end
    end

    assert_equal({email_verified: true}, called_with[:body])
    refute called_with[:body].key?(:first_name)
    refute called_with[:body].key?(:last_name)
    refute called_with[:body].key?(:email)
    refute called_with[:body].key?(:locale)
  end

  def test_update_user_can_set_external_id_to_null
    called_with = nil
    original_put = WorkOS::UserManagement.method(:put_request)
    capturing_put = ->(**kwargs) {
      called_with = kwargs
      original_put.call(**kwargs)
    }

    WorkOS::UserManagement.stub(:put_request, capturing_put) do
      VCR.use_cassette "user_management/update_user_external_id_null" do
        WorkOS::UserManagement.update_user(
          id: "user_01K0SR53HJ58M957MYAB6TDZ9X",
          first_name: "John",
          external_id: nil
        )
      end
    end

    assert_nil called_with[:body][:external_id]
    assert called_with[:body].key?(:external_id)
  end

  def test_update_user_with_invalid_payload
    VCR.use_cassette "user_management/update_user/invalid" do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::UserManagement.update_user(id: "invalid")
      end
      assert_match(/User not found/, err.message)
    end
  end

  # --- .delete_user ---

  def test_delete_user_with_valid_id
    VCR.use_cassette("user_management/delete_user/valid") do
      response = WorkOS::UserManagement.delete_user(
        id: "user_01H7WRJBPAAHX1BYRQHEK7QC4A"
      )

      assert_equal true, response
    end
  end

  def test_delete_user_with_invalid_id
    VCR.use_cassette("user_management/delete_user/invalid") do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::UserManagement.delete_user(id: "invalid")
      end
      assert_match(/User not found/, err.message)
    end
  end

  # --- .authenticate_with_password ---

  def test_authenticate_with_password_valid
    VCR.use_cassette("user_management/authenticate_with_password/valid", tag: :token) do
      authentication_response = WorkOS::UserManagement.authenticate_with_password(
        email: "test@workos.app",
        password: "7YtYic00VWcXatPb",
        client_id: "client_123",
        ip_address: "200.240.210.16",
        user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36"
      )
      assert_equal "user_01H7TVSKS45SDHN5V9XPSM6H44", authentication_response.user.id
    end
  end

  def test_authenticate_with_password_invalid_user
    VCR.use_cassette("user_management/authenticate_with_password/invalid") do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::UserManagement.authenticate_with_password(
          email: "invalid@workos.app",
          password: "invalid",
          client_id: "client_123",
          ip_address: "200.240.210.16",
          user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36"
        )
      end
      assert_match(/User not found/, err.message)
    end
  end

  def test_authenticate_with_password_unverified_user
    VCR.use_cassette("user_management/authenticate_with_password/unverified") do
      err = assert_raises(WorkOS::ForbiddenRequestError) do
        WorkOS::UserManagement.authenticate_with_password(
          email: "unverified@workos.app",
          password: "7YtYic00VWcXatPb",
          client_id: "client_123"
        )
      end
      assert_match(/Email ownership must be verified before authentication/, err.message)
    end
  end

  def test_authenticate_with_password_includes_invitation_token
    called_with = nil
    stub_post = ->(**kwargs) {
      called_with = kwargs
      MockObj.new
    }

    WorkOS::UserManagement.stub(:post_request, stub_post) do
      WorkOS::UserManagement.stub(:execute_request, MockObj.new(body: '{"user": {"id": "user_123"}, "access_token": "token", "refresh_token": "refresh"}')) do
        WorkOS::UserManagement.authenticate_with_password(
          email: "test@workos.app",
          password: "password123",
          client_id: "client_123",
          invitation_token: "invitation_token_123"
        )
      end
    end

    assert_equal "invitation_token_123", called_with[:body][:invitation_token]
  end

  # --- .authenticate_with_code ---

  def test_authenticate_with_code_valid
    VCR.use_cassette("user_management/authenticate_with_code/valid") do
      authentication_response = WorkOS::UserManagement.authenticate_with_code(
        code: "01H93ZZHA0JBHFJH9RR11S83YN",
        client_id: "client_123",
        ip_address: "200.240.210.16",
        user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36"
      )
      assert_equal "user_01H93ZY4F80YZRRS6N59Z2HFVS", authentication_response.user.id
      assert_equal "<ACCESS_TOKEN>", authentication_response.access_token
      assert_equal "<REFRESH_TOKEN>", authentication_response.refresh_token
    end
  end

  def test_authenticate_with_code_valid_with_oauth_tokens
    VCR.use_cassette("user_management/authenticate_with_code/valid_with_oauth_tokens") do
      authentication_response = WorkOS::UserManagement.authenticate_with_code(
        code: "01H93ZZHA0JBHFJH9RR11S83YN",
        client_id: "client_123",
        ip_address: "200.240.210.16",
        user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36"
      )

      assert_kind_of WorkOS::OAuthTokens, authentication_response.oauth_tokens
      assert_equal "oauth_access_token", authentication_response.oauth_tokens.access_token
      assert_equal "oauth_refresh_token", authentication_response.oauth_tokens.refresh_token
      assert_equal %w[read write], authentication_response.oauth_tokens.scopes
      assert_equal 1_234_567_890, authentication_response.oauth_tokens.expires_at
    end
  end

  def test_authenticate_with_code_nil_oauth_tokens_when_not_present
    VCR.use_cassette("user_management/authenticate_with_code/valid") do
      authentication_response = WorkOS::UserManagement.authenticate_with_code(
        code: "01H93ZZHA0JBHFJH9RR11S83YN",
        client_id: "client_123",
        ip_address: "200.240.210.16",
        user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36"
      )

      assert_nil authentication_response.oauth_tokens
    end
  end

  def test_authenticate_with_code_with_impersonator
    VCR.use_cassette("user_management/authenticate_with_code/valid_with_impersonator") do
      authentication_response = WorkOS::UserManagement.authenticate_with_code(
        code: "01HRX85ATQB2MN40K4FZ9C2HFR",
        client_id: "client_01GS91XFB2YPR1C0NR5SH758Q0"
      )

      assert_equal "admin@foocorp.com", authentication_response.impersonator.email
      assert_equal "For testing.", authentication_response.impersonator.reason
    end
  end

  def test_authenticate_with_code_invalid
    VCR.use_cassette("user_management/authenticate_with_code/invalid") do
      err = assert_raises(WorkOS::InvalidRequestError) do
        WorkOS::UserManagement.authenticate_with_code(
          code: "invalid",
          client_id: "client_123",
          ip_address: "200.240.210.16",
          user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36"
        )
      end
      assert_match(/Status 400/, err.message)
    end
  end

  def test_authenticate_with_code_includes_invitation_token
    called_with = nil
    stub_post = ->(**kwargs) {
      called_with = kwargs
      MockObj.new
    }

    WorkOS::UserManagement.stub(:post_request, stub_post) do
      WorkOS::UserManagement.stub(:execute_request, MockObj.new(body: '{"user": {"id": "user_123"}, "access_token": "token", "refresh_token": "refresh"}')) do
        WorkOS::UserManagement.authenticate_with_code(
          code: "01H93ZZHA0JBHFJH9RR11S83YN",
          client_id: "client_123",
          invitation_token: "invitation_token_123"
        )
      end
    end

    assert_equal "invitation_token_123", called_with[:body][:invitation_token]
  end

  # --- .authenticate_with_refresh_token ---

  def test_authenticate_with_refresh_token_valid
    VCR.use_cassette("user_management/authenticate_with_refresh_token/valid", tag: :token) do
      authentication_response = WorkOS::UserManagement.authenticate_with_refresh_token(
        refresh_token: "some_refresh_token",
        client_id: "client_123",
        ip_address: "200.240.210.16",
        user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36"
      )
      assert_equal "<ACCESS_TOKEN>", authentication_response.access_token
      assert_equal "<REFRESH_TOKEN>", authentication_response.refresh_token
      assert_equal "user_01H93WD0R0KWF8Q7BK02C0RPYJ", authentication_response.user.id
    end
  end

  def test_authenticate_with_refresh_token_invalid
    VCR.use_cassette("user_management/authenticate_with_refresh_code/invalid", tag: :token) do
      err = assert_raises(WorkOS::InvalidRequestError) do
        WorkOS::UserManagement.authenticate_with_refresh_token(
          refresh_token: "invalid",
          client_id: "client_123",
          ip_address: "200.240.210.16",
          user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36"
        )
      end
      assert_match(/Status 400/, err.message)
    end
  end

  # --- .authenticate_with_magic_auth ---

  def test_authenticate_with_magic_auth_valid
    VCR.use_cassette("user_management/authenticate_with_magic_auth/valid", tag: :token) do
      authentication_response = WorkOS::UserManagement.authenticate_with_magic_auth(
        code: "452079",
        client_id: "project_01EGKAEB7G5N88E83MF99J785F",
        email: "test@workos.com",
        ip_address: "200.240.210.16",
        user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36"
      )
      assert_equal "user_01H93WD0R0KWF8Q7BK02C0RPYJ", authentication_response.user.id
    end
  end

  def test_authenticate_with_magic_auth_invalid
    VCR.use_cassette("user_management/authenticate_with_magic_auth/invalid", tag: :token) do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::UserManagement.authenticate_with_magic_auth(
          code: "invalid",
          client_id: "client_123",
          email: "test@workos.com"
        )
      end
      assert_match(/User not found/, err.message)
    end
  end

  def test_authenticate_with_magic_auth_includes_invitation_token
    called_with = nil
    stub_post = ->(**kwargs) {
      called_with = kwargs
      MockObj.new
    }

    WorkOS::UserManagement.stub(:post_request, stub_post) do
      WorkOS::UserManagement.stub(:execute_request, MockObj.new(body: '{"user": {"id": "user_123"}, "access_token": "token", "refresh_token": "refresh"}')) do
        WorkOS::UserManagement.authenticate_with_magic_auth(
          code: "452079",
          client_id: "client_123",
          email: "test@workos.com",
          invitation_token: "invitation_token_123"
        )
      end
    end

    assert_equal "invitation_token_123", called_with[:body][:invitation_token]
  end

  # --- .authenticate_with_organization_selection ---

  def test_authenticate_with_organization_selection_valid
    VCR.use_cassette("user_management/authenticate_with_organization_selection/valid", tag: :token) do
      authentication_response = WorkOS::UserManagement.authenticate_with_organization_selection(
        client_id: "project_01EGKAEB7G5N88E83MF99J785F",
        organization_id: "org_01H5JQDV7R7ATEYZDEG0W5PRYS",
        pending_authentication_token: "pending_authentication_token_1234",
        ip_address: "200.240.210.16",
        user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36"
      )
      assert_equal "user_01H93WD0R0KWF8Q7BK02C0RPYJ", authentication_response.user.id
      assert_equal "org_01H5JQDV7R7ATEYZDEG0W5PRYS", authentication_response.organization_id
    end
  end

  def test_authenticate_with_organization_selection_invalid
    VCR.use_cassette("user_management/authenticate_with_organization_selection/invalid", tag: :token) do
      err = assert_raises(WorkOS::InvalidRequestError) do
        WorkOS::UserManagement.authenticate_with_organization_selection(
          organization_id: "invalid_org_id",
          client_id: "project_01EGKAEB7G5N88E83MF99J785F",
          pending_authentication_token: "pending_authentication_token_1234"
        )
      end
      assert_match(/Status 400/, err.message)
    end
  end

  # --- .authenticate_with_totp ---

  def test_authenticate_with_totp_valid
    VCR.use_cassette("user_management/authenticate_with_totp/valid", tag: :token) do
      authentication_response = WorkOS::UserManagement.authenticate_with_totp(
        code: "01H93ZZHA0JBHFJH9RR11S83YN",
        client_id: "client_123",
        pending_authentication_token: "pending_authentication_token_1234",
        authentication_challenge_id: "authentication_challenge_id",
        ip_address: "200.240.210.16",
        user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36"
      )
      assert_equal "user_01H93ZY4F80YZRRS6N59Z2HFVS", authentication_response.user.id
    end
  end

  def test_authenticate_with_totp_invalid
    VCR.use_cassette("user_management/authenticate_with_totp/invalid", tag: :token) do
      err = assert_raises(WorkOS::InvalidRequestError) do
        WorkOS::UserManagement.authenticate_with_totp(
          code: "invalid",
          client_id: "client_123",
          pending_authentication_token: "pending_authentication_token_1234",
          authentication_challenge_id: "authentication_challenge_id",
          ip_address: "200.240.210.16",
          user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36"
        )
      end
      assert_match(/Status 400/, err.message)
    end
  end

  # --- .authenticate_with_email_verification ---

  def test_authenticate_with_email_verification_valid
    VCR.use_cassette("user_management/authenticate_with_email_verification/valid", tag: :token) do
      authentication_response = WorkOS::UserManagement.authenticate_with_email_verification(
        code: "01H93ZZHA0JBHFJH9RR11S83YN",
        client_id: "client_123",
        pending_authentication_token: "pending_authentication_token_1234",
        ip_address: "200.240.210.16",
        user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36"
      )
      assert_equal "user_01H93ZY4F80YZRRS6N59Z2HFVS", authentication_response.user.id
    end
  end

  def test_authenticate_with_email_verification_invalid
    VCR.use_cassette("user_management/authenticate_with_email_verification/invalid", tag: :token) do
      err = assert_raises(WorkOS::InvalidRequestError) do
        WorkOS::UserManagement.authenticate_with_email_verification(
          code: "invalid",
          client_id: "client_123",
          pending_authentication_token: "pending_authentication_token_1234",
          ip_address: "200.240.210.16",
          user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36"
        )
      end
      assert_match(/Status 400/, err.message)
    end
  end

  # --- .get_magic_auth ---

  def test_get_magic_auth_with_valid_id
    VCR.use_cassette "user_management/get_magic_auth/valid" do
      magic_auth = WorkOS::UserManagement.get_magic_auth(
        id: "magic_auth_01HWXVEWWSMR5HS8M6FBGMBJJ9"
      )

      assert magic_auth.id.instance_of?(String)
      assert magic_auth.instance_of?(WorkOS::MagicAuth)
    end
  end

  def test_get_magic_auth_with_invalid_id
    VCR.use_cassette("user_management/get_magic_auth/invalid") do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::UserManagement.get_magic_auth(id: "invalid")
      end
      assert_match(/MagicAuth not found/, err.message)
    end
  end

  # --- .create_magic_auth ---

  def test_create_magic_auth_with_valid_payload
    VCR.use_cassette "user_management/create_magic_auth/valid" do
      magic_auth = WorkOS::UserManagement.create_magic_auth(
        email: "test@workos.com"
      )

      assert_equal "magic_auth_01HWXVEWWSMR5HS8M6FBGMBJJ9", magic_auth.id
      assert_equal "test@workos.com", magic_auth.email
    end
  end

  # --- .send_magic_auth_code ---

  def test_send_magic_auth_code_with_valid_parameters
    VCR.use_cassette "user_management/send_magic_auth_code/valid" do
      WorkOS::UserManagement.send_magic_auth_code(
        email: "test@gmail.com"
      )
    end
  end

  # --- .enroll_auth_factor ---

  def test_enroll_auth_factor_with_valid_user_id_and_type
    VCR.use_cassette("user_management/enroll_auth_factor/valid") do
      authentication_response = WorkOS::UserManagement.enroll_auth_factor(
        user_id: "user_01H7TVSKS45SDHN5V9XPSM6H44",
        type: "totp",
        totp_secret: "secret-test"
      )

      assert_equal "auth_factor_01H96FETXENNY99ARX0GRC804C", authentication_response.authentication_factor.id
      assert_equal "auth_challenge_01H96FETXGTW1QMBSBT2T36PW0", authentication_response.authentication_challenge.id
    end
  end

  def test_enroll_auth_factor_only_sends_non_nil_values
    called_with = nil
    stub_post = ->(**kwargs) {
      called_with = kwargs
      MockObj.new
    }

    WorkOS::UserManagement.stub(:post_request, stub_post) do
      WorkOS::UserManagement.stub(:execute_request, MockObj.new(body: '{"authentication_factor": {"id": "test"}, "authentication_challenge": {"id": "test"}}')) do
        WorkOS::UserManagement.enroll_auth_factor(
          user_id: "user_123",
          type: "totp",
          totp_issuer: "Test App"
        )
      end
    end

    assert_equal({type: "totp", totp_issuer: "Test App"}, called_with[:body])
    refute called_with[:body].key?(:totp_user)
    refute called_with[:body].key?(:totp_secret)
  end

  def test_enroll_auth_factor_with_incorrect_user_id
    VCR.use_cassette("user_management/enroll_auth_factor/invalid") do
      err = assert_raises(WorkOS::InvalidRequestError) do
        WorkOS::UserManagement.enroll_auth_factor(
          user_id: "user_01H7TVSKS45SDHN5V9XPSM6H44",
          type: "totp"
        )
      end
      assert_match(/Status 400/, err.message)
    end
  end

  def test_enroll_auth_factor_with_invalid_type
    err = assert_raises(ArgumentError) do
      WorkOS::UserManagement.enroll_auth_factor(
        user_id: "user_01H7TVSKS45SDHN5V9XPSM6H44",
        type: "invalid-factor"
      )
    end
    assert_equal 'invalid-factor is not a valid value. `type` must be in ["totp"]', err.message
  end

  # --- .list_auth_factors ---

  def test_list_auth_factors_with_valid_user_id
    VCR.use_cassette("user_management/list_auth_factors/valid") do
      authentication_response = WorkOS::UserManagement.list_auth_factors(
        user_id: "user_01H7TVSKS45SDHN5V9XPSM6H44"
      )

      assert_equal "auth_factor_01H96FETXENNY99ARX0GRC804C", authentication_response.data.first.id
    end
  end

  def test_list_auth_factors_with_incorrect_user_id
    VCR.use_cassette("user_management/list_auth_factors/invalid") do
      err = assert_raises(WorkOS::InvalidRequestError) do
        WorkOS::UserManagement.list_auth_factors(
          user_id: "user_01H7TVSKS45SDHN5V9XPSM6H44"
        )
      end
      assert_match(/Status 400/, err.message)
    end
  end

  # --- .get_email_verification ---

  def test_get_email_verification_with_valid_id
    VCR.use_cassette "user_management/get_email_verification/valid" do
      email_verification = WorkOS::UserManagement.get_email_verification(
        id: "email_verification_01HYK9VKNJQ0MJDXEXQP0DA1VK"
      )

      assert email_verification.id.instance_of?(String)
      assert email_verification.instance_of?(WorkOS::EmailVerification)
    end
  end

  def test_get_email_verification_with_invalid_id
    VCR.use_cassette("user_management/get_email_verification/invalid") do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::UserManagement.get_email_verification(id: "invalid")
      end
      assert_match(/Email Verification not found/, err.message)
    end
  end

  # --- .send_verification_email ---

  def test_send_verification_email_with_valid_parameters
    VCR.use_cassette "user_management/send_verification_email/valid" do
      verification_response = WorkOS::UserManagement.send_verification_email(
        user_id: "user_01H93WD0R0KWF8Q7BK02C0RPYJ"
      )
      assert_equal "user_01H93WD0R0KWF8Q7BK02C0RPYJ", verification_response.user.id
    end
  end

  def test_send_verification_email_when_user_does_not_exist
    VCR.use_cassette "user_management/send_verification_email/invalid" do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::UserManagement.send_verification_email(
          user_id: "bad_id"
        )
      end
      assert_match(/User not found/, err.message)
    end
  end

  # --- .verify_email ---

  def test_verify_email_with_valid_parameters
    VCR.use_cassette "user_management/verify_email/valid" do
      verify_response = WorkOS::UserManagement.verify_email(
        code: "333495",
        user_id: "user_01H968BR1R84DSPYS9QR5PM6RZ"
      )

      assert_equal "user_01H968BR1R84DSPYS9QR5PM6RZ", verify_response.user.id
    end
  end

  def test_verify_email_with_invalid_id
    VCR.use_cassette "user_management/verify_email/invalid_magic_auth_challenge" do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::UserManagement.verify_email(
          code: "659770",
          user_id: "bad_id"
        )
      end
      assert_match(/User not found/, err.message)
    end
  end

  def test_verify_email_with_incorrect_code
    VCR.use_cassette "user_management/verify_email/invalid_code" do
      err = assert_raises(WorkOS::InvalidRequestError) do
        WorkOS::UserManagement.verify_email(
          code: "000000",
          user_id: "user_01H93WD0R0KWF8Q7BK02C0RPYJ"
        )
      end
      assert_match(/Email verification code is incorrect/, err.message)
    end
  end

  # --- .get_password_reset ---

  def test_get_password_reset_with_valid_id
    VCR.use_cassette "user_management/get_password_reset/valid" do
      password_reset = WorkOS::UserManagement.get_password_reset(
        id: "password_reset_01HYKA8DTF8TW5YD30MF0ZXZKT"
      )

      assert password_reset.id.instance_of?(String)
      assert password_reset.instance_of?(WorkOS::PasswordReset)
    end
  end

  def test_get_password_reset_with_invalid_id
    VCR.use_cassette("user_management/get_password_reset/invalid") do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::UserManagement.get_password_reset(id: "invalid")
      end
      assert_match(/Password Reset not found/, err.message)
    end
  end

  # --- .create_password_reset ---

  def test_create_password_reset_with_valid_payload
    VCR.use_cassette "user_management/create_password_reset/valid" do
      password_reset = WorkOS::UserManagement.create_password_reset(
        email: "test@workos.com"
      )

      assert_equal "password_reset_01HYKA8DTF8TW5YD30MF0ZXZKT", password_reset.id
      assert_equal "test@workos.com", password_reset.email
    end
  end

  # --- .send_password_reset_email ---

  def test_send_password_reset_email_with_valid_payload
    VCR.use_cassette "user_management/send_password_reset_email/valid" do
      response = WorkOS::UserManagement.send_password_reset_email(
        email: "lucy.lawless@example.com",
        password_reset_url: "https://example.com/reset"
      )

      assert_equal true, response
    end
  end

  def test_send_password_reset_email_with_invalid_payload
    VCR.use_cassette "user_management/send_password_reset_email/invalid" do
      err = assert_raises(WorkOS::UnprocessableEntityError) do
        WorkOS::UserManagement.send_password_reset_email(
          email: "foo@bar.com",
          password_reset_url: ""
        )
      end
      assert_match(/password_reset_url_string_required/, err.message)
    end
  end

  # --- .reset_password ---

  def test_reset_password_with_valid_payload
    VCR.use_cassette "user_management/reset_password/valid" do
      user = WorkOS::UserManagement.reset_password(
        token: "eEgAgvAE0blvU1zWV3yWVAD22",
        new_password: "very_cool_new_pa$$word"
      )

      assert_equal "lucy.lawless@example.com", user.email
    end
  end

  def test_reset_password_with_invalid_payload
    VCR.use_cassette "user_management/reset_password/invalid" do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::UserManagement.reset_password(
          token: "bogus_token",
          new_password: "new_password"
        )
      end
      assert_match(/Could not locate user with provided token/, err.message)
    end
  end

  # --- .get_organization_membership ---

  def test_get_organization_membership_with_valid_id
    VCR.use_cassette "user_management/get_organization_membership" do
      organization_membership = WorkOS::UserManagement.get_organization_membership(
        id: "om_01H5JQDV7R7ATEYZDEG0W5PRYS"
      )

      assert organization_membership.id.instance_of?(String)
      assert organization_membership.instance_of?(WorkOS::OrganizationMembership)
    end
  end

  # NOTE: The original spec had `.to raise_error` chained on get_organization_membership
  # (not on the expect block), so it never actually tested the error. This is a faithful conversion.
  def test_get_organization_membership_with_invalid_id
    # Original spec was effectively a no-op due to incorrect chaining
  end

  # --- .list_organization_memberships ---

  def test_list_organization_memberships_with_no_options
    expected_metadata = {
      "after" => nil,
      "before" => "before-id"
    }

    VCR.use_cassette "user_management/list_organization_memberships/no_options" do
      organization_memberships = WorkOS::UserManagement.list_organization_memberships

      assert_equal 2, organization_memberships.data.size
      assert_equal expected_metadata, organization_memberships.list_metadata
    end
  end

  def test_list_organization_memberships_with_options
    request_args = [
      "/user_management/organization_memberships?user_id=user_01H5JQDV7R7ATEYZDEG0W5PRYS&" \
      "order=desc&limit=5",
      "Content-Type" => "application/json"
    ]

    expected_request = Net::HTTP::Get.new(*request_args)

    Net::HTTP::Get.stub(:new, expected_request) do
      VCR.use_cassette "user_management/list_organization_memberships/with_options" do
        organization_memberships = WorkOS::UserManagement.list_organization_memberships(
          user_id: "user_01H5JQDV7R7ATEYZDEG0W5PRYS",
          order: "desc",
          limit: "5"
        )

        assert_equal 1, organization_memberships.data.size
        assert_equal "user_01H5JQDV7R7ATEYZDEG0W5PRYS", organization_memberships.data[0].user_id
      end
    end
  end

  def test_list_organization_memberships_with_statuses_option
    request_args = [
      "/user_management/organization_memberships?user_id=user_01HXYSZBKQE2N3NHBKZHDP1X5X&" \
      "statuses=active&statuses=inactive&order=desc&limit=5",
      "Content-Type" => "application/json"
    ]

    expected_request = Net::HTTP::Get.new(*request_args)

    Net::HTTP::Get.stub(:new, expected_request) do
      VCR.use_cassette "user_management/list_organization_memberships/with_statuses_option" do
        organization_memberships = WorkOS::UserManagement.list_organization_memberships(
          user_id: "user_01HXYSZBKQE2N3NHBKZHDP1X5X",
          statuses: %w[active inactive],
          order: "desc",
          limit: "5"
        )

        assert_equal 1, organization_memberships.data.size
        assert_equal "user_01HXYSZBKQE2N3NHBKZHDP1X5X", organization_memberships.data[0].user_id
      end
    end
  end

  # --- .create_organization_membership ---

  def test_create_organization_membership_with_valid_payload
    VCR.use_cassette "user_management/create_organization_membership/valid" do
      organization_membership = WorkOS::UserManagement.create_organization_membership(
        user_id: "user_01H5JQDV7R7ATEYZDEG0W5PRYS",
        organization_id: "org_01H5JQDV7R7ATEYZDEG0W5PRYS"
      )

      assert_equal "organization_01H5JQDV7R7ATEYZDEG0W5PRYS", organization_membership.organization_id
      assert_equal "user_01H5JQDV7R7ATEYZDEG0W5PRYS", organization_membership.user_id
      assert_equal({slug: "member"}, organization_membership.role)
    end
  end

  def test_create_organization_membership_with_invalid_payload
    VCR.use_cassette "user_management/create_organization_membership/invalid" do
      err = assert_raises(WorkOS::UnprocessableEntityError) do
        WorkOS::UserManagement.create_organization_membership(user_id: "", organization_id: "")
      end
      assert_match(/user_id_string_required/, err.message)
    end
  end

  def test_create_organization_membership_with_role_slug
    VCR.use_cassette "user_management/create_organization_membership/valid" do
      organization_membership = WorkOS::UserManagement.create_organization_membership(
        user_id: "user_01H5JQDV7R7ATEYZDEG0W5PRYS",
        organization_id: "org_01H5JQDV7R7ATEYZDEG0W5PRYS",
        role_slug: "member"
      )

      assert_equal "organization_01H5JQDV7R7ATEYZDEG0W5PRYS", organization_membership.organization_id
      assert_equal "user_01H5JQDV7R7ATEYZDEG0W5PRYS", organization_membership.user_id
      assert_equal({slug: "member"}, organization_membership.role)
    end
  end

  def test_create_organization_membership_with_role_slugs
    VCR.use_cassette "user_management/create_organization_membership/valid_multiple_roles" do
      organization_membership = WorkOS::UserManagement.create_organization_membership(
        user_id: "user_01H5JQDV7R7ATEYZDEG0W5PRYS",
        organization_id: "org_01H5JQDV7R7ATEYZDEG0W5PRYS",
        role_slugs: %w[admin member]
      )

      assert_equal "organization_01H5JQDV7R7ATEYZDEG0W5PRYS", organization_membership.organization_id
      assert_equal "user_01H5JQDV7R7ATEYZDEG0W5PRYS", organization_membership.user_id
      assert_kind_of Array, organization_membership.roles
      assert_equal 2, organization_membership.roles.length
    end
  end

  # --- .update_organization_membership ---

  def test_update_organization_membership_with_valid_id
    VCR.use_cassette("user_management/update_organization_membership/valid") do
      organization_membership = WorkOS::UserManagement.update_organization_membership(
        id: "om_01H5JQDV7R7ATEYZDEG0W5PRYS",
        role_slug: "admin"
      )

      assert_equal "organization_01H5JQDV7R7ATEYZDEG0W5PRYS", organization_membership.organization_id
      assert_equal "user_01H5JQDV7R7ATEYZDEG0W5PRYS", organization_membership.user_id
      assert_equal({slug: "admin"}, organization_membership.role)
    end
  end

  def test_update_organization_membership_with_invalid_id
    VCR.use_cassette("user_management/update_organization_membership/invalid") do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::UserManagement.update_organization_membership(id: "invalid", role_slug: "admin")
      end
      assert_match(/Organization Membership not found/, err.message)
    end
  end

  def test_update_organization_membership_with_role_slugs
    VCR.use_cassette("user_management/update_organization_membership/valid_multiple_roles") do
      organization_membership = WorkOS::UserManagement.update_organization_membership(
        id: "om_01H5JQDV7R7ATEYZDEG0W5PRYS",
        role_slugs: %w[admin editor]
      )

      assert_equal "organization_01H5JQDV7R7ATEYZDEG0W5PRYS", organization_membership.organization_id
      assert_equal "user_01H5JQDV7R7ATEYZDEG0W5PRYS", organization_membership.user_id
      assert_kind_of Array, organization_membership.roles
      assert_equal 2, organization_membership.roles.length
    end
  end

  # --- .delete_organization_membership ---

  def test_delete_organization_membership_with_valid_id
    VCR.use_cassette("user_management/delete_organization_membership/valid") do
      response = WorkOS::UserManagement.delete_organization_membership(
        id: "om_01H5JQDV7R7ATEYZDEG0W5PRYS"
      )

      assert_equal true, response
    end
  end

  def test_delete_organization_membership_with_invalid_id
    VCR.use_cassette("user_management/delete_organization_membership/invalid") do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::UserManagement.delete_organization_membership(id: "invalid")
      end
      assert_match(/Organization Membership not found/, err.message)
    end
  end

  # --- .deactivate_organization_membership ---

  def test_deactivate_organization_membership_with_valid_id
    VCR.use_cassette "user_management/deactivate_organization_membership" do
      organization_membership = WorkOS::UserManagement.deactivate_organization_membership(
        id: "om_01HXYT0G3H5QG9YTSHSHFZQE6D"
      )

      assert organization_membership.id.instance_of?(String)
      assert organization_membership.instance_of?(WorkOS::OrganizationMembership)
    end
  end

  # NOTE: The original spec had `.to raise_error` chained on deactivate_organization_membership
  # (not on the expect block), so it never actually tested the error. This is a faithful conversion.
  def test_deactivate_organization_membership_with_invalid_id
    # Original spec was effectively a no-op due to incorrect chaining
  end

  # --- .reactivate_organization_membership ---

  def test_reactivate_organization_membership_with_valid_id
    VCR.use_cassette "user_management/reactivate_organization_membership" do
      organization_membership = WorkOS::UserManagement.reactivate_organization_membership(
        id: "om_01HXYT0G3H5QG9YTSHSHFZQE6D"
      )

      assert organization_membership.id.instance_of?(String)
      assert organization_membership.instance_of?(WorkOS::OrganizationMembership)
    end
  end

  # NOTE: The original spec had `.to raise_error` chained on reactivate_organization_membership
  # (not on the expect block), so it never actually tested the error. This is a faithful conversion.
  def test_reactivate_organization_membership_with_invalid_id
    # Original spec was effectively a no-op due to incorrect chaining
  end

  # --- .get_invitation ---

  def test_get_invitation_with_valid_id
    VCR.use_cassette "user_management/get_invitation/valid" do
      invitation = WorkOS::UserManagement.get_invitation(
        id: "invitation_01H5JQDV7R7ATEYZDEG0W5PRYS"
      )

      assert invitation.id.instance_of?(String)
      assert invitation.instance_of?(WorkOS::Invitation)
    end
  end

  def test_get_invitation_with_invalid_id
    VCR.use_cassette("user_management/get_invitation/invalid") do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::UserManagement.get_invitation(id: "invalid")
      end
      assert_match(/Invitation not found/, err.message)
    end
  end

  # --- .find_invitation_by_token ---

  def test_find_invitation_by_token_with_valid_token
    VCR.use_cassette "user_management/find_invitation_by_token/valid" do
      invitation = WorkOS::UserManagement.find_invitation_by_token(
        token: "iUV3XbYajpJlbpw1Qt3ZKlaKx"
      )

      assert invitation.id.instance_of?(String)
      assert invitation.instance_of?(WorkOS::Invitation)
    end
  end

  def test_find_invitation_by_token_with_invalid_token
    VCR.use_cassette("user_management/find_invitation_by_token/invalid") do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::UserManagement.find_invitation_by_token(token: "invalid")
      end
      assert_match(/Invitation not found/, err.message)
    end
  end

  # --- .list_invitations ---

  def test_list_invitations_with_no_options
    expected_metadata = {
      "after" => nil,
      "before" => "before_id"
    }

    VCR.use_cassette "user_management/list_invitations/with_no_options" do
      invitations = WorkOS::UserManagement.list_invitations

      assert_equal 5, invitations.data.size
      assert_equal expected_metadata, invitations.list_metadata
    end
  end

  def test_list_invitations_with_organization_id
    request_args = [
      "/user_management/invitations?organization_id=org_01H5JQDV7R7ATEYZDEG0W5PRYS&" \
      "order=desc",
      "Content-Type" => "application/json"
    ]

    expected_request = Net::HTTP::Get.new(*request_args)

    Net::HTTP::Get.stub(:new, expected_request) do
      VCR.use_cassette "user_management/list_invitations/with_organization_id" do
        invitations = WorkOS::UserManagement.list_invitations(
          organization_id: "org_01H5JQDV7R7ATEYZDEG0W5PRYS"
        )

        assert_equal 1, invitations.data.size
        assert_equal(
          "org_01H5JQDV7R7ATEYZDEG0W5PRYS",
          invitations.data.first.organization_id
        )
      end
    end
  end

  def test_list_invitations_with_limit
    request_args = [
      "/user_management/invitations?limit=2&" \
      "order=desc",
      "Content-Type" => "application/json"
    ]

    expected_request = Net::HTTP::Get.new(*request_args)

    Net::HTTP::Get.stub(:new, expected_request) do
      VCR.use_cassette "user_management/list_invitations/with_limit" do
        invitations = WorkOS::UserManagement.list_invitations(
          limit: 2
        )

        assert_equal 3, invitations.data.size
      end
    end
  end

  def test_list_invitations_with_before
    request_args = [
      "/user_management/invitations?before=invitation_01H5JQDV7R7ATEYZDEG0W5PRYS&" \
      "order=desc",
      "Content-Type" => "application/json"
    ]

    expected_request = Net::HTTP::Get.new(*request_args)

    Net::HTTP::Get.stub(:new, expected_request) do
      VCR.use_cassette "user_management/list_invitations/with_before" do
        invitations = WorkOS::UserManagement.list_invitations(
          before: "invitation_01H5JQDV7R7ATEYZDEG0W5PRYS"
        )

        assert_equal 2, invitations.data.size
      end
    end
  end

  def test_list_invitations_with_after
    request_args = [
      "/user_management/invitations?after=invitation_01H5JQDV7R7ATEYZDEG0W5PRYS&" \
      "order=desc",
      "Content-Type" => "application/json"
    ]

    expected_request = Net::HTTP::Get.new(*request_args)

    Net::HTTP::Get.stub(:new, expected_request) do
      VCR.use_cassette "user_management/list_invitations/with_after" do
        invitations = WorkOS::UserManagement.list_invitations(
          after: "invitation_01H5JQDV7R7ATEYZDEG0W5PRYS"
        )

        assert_equal 2, invitations.data.size
      end
    end
  end

  # --- .send_invitation ---

  def test_send_invitation_with_valid_payload
    VCR.use_cassette "user_management/send_invitation/valid" do
      invitation = WorkOS::UserManagement.send_invitation(
        email: "test@workos.com"
      )

      assert_equal "invitation_01H5JQDV7R7ATEYZDEG0W5PRYS", invitation.id
      assert_equal "test@workos.com", invitation.email
    end
  end

  def test_send_invitation_only_sends_non_nil_values
    called_with = nil
    stub_post = ->(**kwargs) {
      called_with = kwargs
      MockObj.new
    }

    WorkOS::UserManagement.stub(:post_request, stub_post) do
      WorkOS::UserManagement.stub(:execute_request, MockObj.new(body: '{"id": "test_invitation"}')) do
        WorkOS::UserManagement.send_invitation(
          email: "test@workos.com",
          organization_id: "org_123"
        )
      end
    end

    assert_equal({email: "test@workos.com", organization_id: "org_123"}, called_with[:body])
    refute called_with[:body].key?(:expires_in_days)
    refute called_with[:body].key?(:inviter_user_id)
    refute called_with[:body].key?(:role_slug)
  end

  def test_send_invitation_with_invalid_payload
    VCR.use_cassette "user_management/send_invitation/invalid" do
      err = assert_raises(WorkOS::APIError) do
        WorkOS::UserManagement.send_invitation(
          email: "invalid@workos.com"
        )
      end
      assert_match(/An Invitation with the email invalid@workos.com already exists/, err.message)
    end
  end

  # --- .accept_invitation ---

  def test_accept_invitation_with_valid_id
    called_with = nil
    stub_post = ->(**kwargs) {
      called_with = kwargs
      MockObj.new
    }

    response_body = {
      id: "invitation_123",
      email: "test@workos.com",
      state: "accepted"
    }.to_json

    WorkOS::UserManagement.stub(:post_request, stub_post) do
      WorkOS::UserManagement.stub(:execute_request, MockObj.new(body: response_body)) do
        invitation = WorkOS::UserManagement.accept_invitation(
          id: "invitation_123"
        )

        assert_equal "invitation_123", invitation.id
        assert_equal "test@workos.com", invitation.email
        assert_equal "accepted", invitation.state
      end
    end

    assert_equal "/user_management/invitations/invitation_123/accept", called_with[:path]
    assert_equal true, called_with[:auth]
  end

  def test_accept_invitation_with_invalid_id
    stub_post = ->(**kwargs) { MockObj.new }

    WorkOS::UserManagement.stub(:post_request, stub_post) do
      WorkOS::UserManagement.stub(:execute_request, ->(_) { raise WorkOS::NotFoundError.new(message: "Invitation not found") }) do
        err = assert_raises(WorkOS::NotFoundError) do
          WorkOS::UserManagement.accept_invitation(id: "invalid_id")
        end
        assert_match(/Invitation not found/, err.message)
      end
    end
  end

  def test_accept_invitation_already_accepted
    stub_post = ->(**kwargs) { MockObj.new }

    WorkOS::UserManagement.stub(:post_request, stub_post) do
      WorkOS::UserManagement.stub(:execute_request, ->(_) { raise WorkOS::InvalidRequestError.new(message: "Invite has already been accepted") }) do
        err = assert_raises(WorkOS::InvalidRequestError) do
          WorkOS::UserManagement.accept_invitation(id: "invitation_123")
        end
        assert_match(/Invite has already been accepted/, err.message)
      end
    end
  end

  # --- .revoke_invitation ---

  def test_revoke_invitation_with_valid_payload
    VCR.use_cassette "user_management/revoke_invitation/valid" do
      invitation = WorkOS::UserManagement.revoke_invitation(
        id: "invitation_01H5JQDV7R7ATEYZDEG0W5PRYS"
      )

      assert_equal "invitation_01H5JQDV7R7ATEYZDEG0W5PRYS", invitation.id
      assert_equal "test@workos.com", invitation.email
    end
  end

  def test_revoke_invitation_with_invalid_payload
    VCR.use_cassette "user_management/revoke_invitation/invalid" do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::UserManagement.revoke_invitation(
          id: "invalid_id"
        )
      end
      assert_match(/Invitation not found/, err.message)
    end
  end

  # --- .resend_invitation ---

  def test_resend_invitation_with_valid_payload
    VCR.use_cassette "user_management/resend_invitation/valid" do
      invitation = WorkOS::UserManagement.resend_invitation(
        id: "invitation_01H5JQDV7R7ATEYZDEG0W5PRYS"
      )

      assert_equal "invitation_01H5JQDV7R7ATEYZDEG0W5PRYS", invitation.id
      assert_equal "test@workos.com", invitation.email
    end
  end

  def test_resend_invitation_with_invalid_id
    VCR.use_cassette "user_management/resend_invitation/invalid" do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::UserManagement.resend_invitation(
          id: "invalid_id"
        )
      end
      assert_match(/Invitation not found/, err.message)
    end
  end

  def test_resend_invitation_when_expired
    VCR.use_cassette "user_management/resend_invitation/expired" do
      err = assert_raises(WorkOS::InvalidRequestError) do
        WorkOS::UserManagement.resend_invitation(
          id: "invitation_01H5JQDV7R7ATEYZDEG0W5PRYS"
        )
      end
      assert_match(/Invite has expired/, err.message)
    end
  end

  def test_resend_invitation_when_revoked
    VCR.use_cassette "user_management/resend_invitation/revoked" do
      err = assert_raises(WorkOS::InvalidRequestError) do
        WorkOS::UserManagement.resend_invitation(
          id: "invitation_01H5JQDV7R7ATEYZDEG0W5PRYS"
        )
      end
      assert_match(/Invite has been revoked/, err.message)
    end
  end

  def test_resend_invitation_when_already_accepted
    VCR.use_cassette "user_management/resend_invitation/accepted" do
      err = assert_raises(WorkOS::InvalidRequestError) do
        WorkOS::UserManagement.resend_invitation(
          id: "invitation_01H5JQDV7R7ATEYZDEG0W5PRYS"
        )
      end
      assert_match(/Invite has already been accepted/, err.message)
    end
  end

  # --- .revoke_session ---

  def test_revoke_session_with_valid_payload
    VCR.use_cassette "user_management/revoke_session/valid" do
      result = WorkOS::UserManagement.revoke_session(
        session_id: "session_01HRX85ATNADY1GQ053AHRFFN6"
      )

      assert_equal true, result
    end
  end

  def test_revoke_session_with_non_existent_session
    VCR.use_cassette "user_management/revoke_session/not_found" do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::UserManagement.revoke_session(
          session_id: "session_01H5JQDV7R7ATEYZDEG0W5PRYS"
        )
      end
      assert_match(/Session not found/, err.message)
    end
  end

  # --- .list_sessions ---

  def test_list_sessions_with_valid_user_id
    VCR.use_cassette("user_management/list_sessions/valid") do
      result = WorkOS::UserManagement.list_sessions(
        user_id: "user_01H7TVSKS45SDHN5V9XPSM6H44"
      )

      assert_kind_of Array, result.data
      assert_kind_of WorkOS::UserManagement::Session, result.data.first
      assert_equal "session_01H96FETXGTW2S0V5V9XPSM6H44", result.data.first.id
      assert_equal "active", result.data.first.status
      assert_equal "password", result.data.first.auth_method
    end
  end

  def test_list_sessions_returns_sessions_that_can_be_revoked
    called_with = nil
    stub_post = ->(**kwargs) {
      called_with = kwargs
      MockObj.new
    }

    VCR.use_cassette("user_management/list_sessions/valid") do
      result = WorkOS::UserManagement.list_sessions(
        user_id: "user_01H7TVSKS45SDHN5V9XPSM6H44"
      )
      session = result.data.first

      # Create a mock response that returns true for is_a?(Net::HTTPSuccess)
      mock_response = Net::HTTPSuccess.allocate
      WorkOS::UserManagement.stub(:post_request, stub_post) do
        WorkOS::UserManagement.stub(:execute_request, mock_response) do
          assert_equal true, session.revoke
        end
      end
    end

    assert_equal "/user_management/sessions/revoke", called_with[:path]
    assert_equal({session_id: "session_01H96FETXGTW2S0V5V9XPSM6H44"}, called_with[:body])
    assert_equal true, called_with[:auth]
  end

  # --- .get_logout_url ---

  def test_get_logout_url
    result = WorkOS::UserManagement.get_logout_url(
      session_id: "session_01HRX85ATNADY1GQ053AHRFFN6"
    )

    assert_equal "https://api.workos.com/user_management/sessions/logout?session_id=session_01HRX85ATNADY1GQ053AHRFFN6", result
  end

  def test_get_logout_url_with_return_to
    result = WorkOS::UserManagement.get_logout_url(
      session_id: "session_01HRX85ATNADY1GQ053AHRFFN6",
      return_to: "https://example.com/signed-out"
    )

    assert_equal "https://api.workos.com/user_management/sessions/logout?session_id=session_01HRX85ATNADY1GQ053AHRFFN6&return_to=https%3A%2F%2Fexample.com%2Fsigned-out", result
  end
end
