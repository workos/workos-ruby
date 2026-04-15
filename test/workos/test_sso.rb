# frozen_string_literal: true

require "test_helper"
require "securerandom"

class TestSSO < WorkOS::TestCase
  def domain_args
    {
      domain: "foo.com",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    }
  end

  def provider_args
    {
      provider: "GoogleOAuth",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    }
  end

  def connection_args
    {
      connection: "connection_123",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    }
  end

  def domain_hint_args
    {
      connection: "connection_123",
      domain_hint: "foo.com",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    }
  end

  def login_hint_args
    {
      connection: "connection_123",
      login_hint: "foo@workos.com",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    }
  end

  def organization_args
    {
      organization: "org_123",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    }
  end

  # authorization_url with a domain

  def test_authorization_url_with_domain_returns_valid_url
    authorization_url = WorkOS::SSO.authorization_url(**domain_args)
    assert_kind_of URI, URI.parse(authorization_url)
  end

  def test_authorization_url_with_domain_returns_expected_hostname
    authorization_url = WorkOS::SSO.authorization_url(**domain_args)
    assert_equal WorkOS.config.api_hostname, URI.parse(authorization_url).host
  end

  def test_authorization_url_with_domain_returns_expected_query_string
    authorization_url = WorkOS::SSO.authorization_url(**domain_args)
    assert_equal(
      "client_id=workos-proj-123&redirect_uri=foo.com%2Fauth%2Fcallback" \
      "&response_type=code&state=%7Bnext_page%3A+%22%2Fdashboard%2Fedit%22%7D&domain=foo.com",
      URI.parse(authorization_url).query
    )
  end

  # authorization_url with a provider

  def test_authorization_url_with_provider_returns_valid_url
    authorization_url = WorkOS::SSO.authorization_url(**provider_args)
    assert_kind_of URI, URI.parse(authorization_url)
  end

  def test_authorization_url_with_provider_returns_expected_hostname
    authorization_url = WorkOS::SSO.authorization_url(**provider_args)
    assert_equal WorkOS.config.api_hostname, URI.parse(authorization_url).host
  end

  def test_authorization_url_with_provider_returns_expected_query_string
    authorization_url = WorkOS::SSO.authorization_url(**provider_args)
    assert_equal(
      "client_id=workos-proj-123&redirect_uri=foo.com%2Fauth%2Fcallback" \
      "&response_type=code&state=%7Bnext_page%3A+%22%2Fdashboard%2Fedit%22%7D&provider=GoogleOAuth",
      URI.parse(authorization_url).query
    )
  end

  # authorization_url with a connection

  def test_authorization_url_with_connection_returns_valid_url
    authorization_url = WorkOS::SSO.authorization_url(**connection_args)
    assert_kind_of URI, URI.parse(authorization_url)
  end

  def test_authorization_url_with_connection_returns_expected_hostname
    authorization_url = WorkOS::SSO.authorization_url(**connection_args)
    assert_equal WorkOS.config.api_hostname, URI.parse(authorization_url).host
  end

  def test_authorization_url_with_connection_returns_expected_query_string
    authorization_url = WorkOS::SSO.authorization_url(**connection_args)
    assert_equal(
      "client_id=workos-proj-123&redirect_uri=foo.com%2Fauth%2Fcallback" \
      "&response_type=code&state=%7Bnext_page%3A+%22%2Fdashboard%2Fedit%22%7D&connection=connection_123",
      URI.parse(authorization_url).query
    )
  end

  # authorization_url with a domain_hint

  def test_authorization_url_with_domain_hint_returns_valid_url
    authorization_url = WorkOS::SSO.authorization_url(**domain_hint_args)
    assert_kind_of URI, URI.parse(authorization_url)
  end

  def test_authorization_url_with_domain_hint_returns_expected_hostname
    authorization_url = WorkOS::SSO.authorization_url(**domain_hint_args)
    assert_equal WorkOS.config.api_hostname, URI.parse(authorization_url).host
  end

  def test_authorization_url_with_domain_hint_returns_expected_query_string
    authorization_url = WorkOS::SSO.authorization_url(**domain_hint_args)
    assert_equal(
      "client_id=workos-proj-123&redirect_uri=foo.com%2Fauth%2Fcallback" \
      "&response_type=code&state=%7Bnext_page%3A+%22%2Fdashboard%2Fedit%22%7D&domain_hint=foo.com&connection=connection_123",
      URI.parse(authorization_url).query
    )
  end

  # authorization_url with a login_hint

  def test_authorization_url_with_login_hint_returns_valid_url
    authorization_url = WorkOS::SSO.authorization_url(**login_hint_args)
    assert_kind_of URI, URI.parse(authorization_url)
  end

  def test_authorization_url_with_login_hint_returns_expected_hostname
    authorization_url = WorkOS::SSO.authorization_url(**login_hint_args)
    assert_equal WorkOS.config.api_hostname, URI.parse(authorization_url).host
  end

  def test_authorization_url_with_login_hint_returns_expected_query_string
    authorization_url = WorkOS::SSO.authorization_url(**login_hint_args)
    assert_equal(
      "client_id=workos-proj-123&redirect_uri=foo.com%2Fauth%2Fcallback" \
      "&response_type=code&state=%7Bnext_page%3A+%22%2Fdashboard%2Fedit%22%7D&login_hint=foo%40workos.com&connection=connection_123",
      URI.parse(authorization_url).query
    )
  end

  # authorization_url with an organization

  def test_authorization_url_with_organization_returns_valid_url
    authorization_url = WorkOS::SSO.authorization_url(**organization_args)
    assert_kind_of URI, URI.parse(authorization_url)
  end

  def test_authorization_url_with_organization_returns_expected_hostname
    authorization_url = WorkOS::SSO.authorization_url(**organization_args)
    assert_equal WorkOS.config.api_hostname, URI.parse(authorization_url).host
  end

  def test_authorization_url_with_organization_returns_expected_query_string
    authorization_url = WorkOS::SSO.authorization_url(**organization_args)
    assert_equal(
      "client_id=workos-proj-123&redirect_uri=foo.com%2Fauth%2Fcallback" \
      "&response_type=code&state=%7Bnext_page%3A+%22%2Fdashboard%2Fedit%22%7D&organization=org_123",
      URI.parse(authorization_url).query
    )
  end

  # authorization_url without connection, domain, provider, or organization

  def test_authorization_url_without_connection_domain_provider_or_organization_raises_error
    args = {
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    }
    err = assert_raises(ArgumentError) do
      WorkOS::SSO.authorization_url(**args)
    end
    assert_equal "Either connection, domain, provider, or organization is required.", err.message
  end

  # authorization_url with an invalid provider

  def test_authorization_url_with_invalid_provider_raises_error
    args = {
      provider: "Okta",
      client_id: "workos-proj-123",
      redirect_uri: "foo.com/auth/callback",
      state: '{next_page: "/dashboard/edit"}'
    }
    err = assert_raises(ArgumentError) do
      WorkOS::SSO.authorization_url(**args)
    end
    assert_equal(
      "Okta is not a valid value. `provider` must be in " \
      '["AppleOAuth", "GitHubOAuth", "GoogleOAuth", "MicrosoftOAuth"]',
      err.message
    )
  end

  # get_profile

  def test_get_profile_returns_a_profile
    VCR.use_cassette "sso/profile" do
      profile = WorkOS::SSO.get_profile(access_token: "access_token")

      expectation = {
        connection_id: "conn_01E83FVYZHY7DM4S9503JHV0R5",
        connection_type: "GoogleOAuth",
        email: "bob.loblaw@workos.com",
        first_name: "Bob",
        id: "prof_01EEJTY9SZ1R350RB7B73SNBKF",
        idp_id: "116485463307139932699",
        last_name: "Loblaw",
        role: {
          slug: "member"
        },
        roles: [{
          slug: "member"
        }],
        groups: nil,
        organization_id: "org_01FG53X8636WSNW2WEKB2C31ZB",
        custom_attributes: {},
        raw_attributes: {
          email: "bob.loblaw@workos.com",
          family_name: "Loblaw",
          given_name: "Bob",
          hd: "workos.com",
          id: "116485463307139932699",
          locale: "en",
          name: "Bob Loblaw",
          picture: "https://lh3.googleusercontent.com/a-/AOh14GyO2hLlgZvteDQ3Ldi3_-RteZLya0hWH7247Cam=s96-c",
          verified_email: true
        }
      }
      assert_equal expectation, profile.to_json
    end
  end

  # profile_and_token - successful response

  def profile_and_token_args
    @profile_and_token_args ||= {
      code: SecureRandom.hex(10),
      client_id: "workos-proj-123"
    }
  end

  def profile_and_token_request_body
    {
      client_id: profile_and_token_args[:client_id],
      client_secret: WorkOS.config.key,
      code: profile_and_token_args[:code],
      grant_type: "authorization_code"
    }
  end

  def test_profile_and_token_includes_sdk_version_header
    with_vcr_off do
      user_agent = "user-agent-string"
      response_body = File.read("#{TEST_ROOT}/fixtures/profile.txt")
      headers = {"User-Agent" => user_agent}

      WorkOS::SSO.stub(:user_agent, user_agent) do
        stub_request(:post, "https://api.workos.com/sso/token")
          .with(headers: headers, body: profile_and_token_request_body)
          .to_return(status: 200, body: response_body)

        WorkOS::SSO.profile_and_token(**profile_and_token_args)

        assert_requested(:post, "https://api.workos.com/sso/token",
          headers: headers, body: profile_and_token_request_body)
      end
    end
  end

  def test_profile_and_token_returns_profile_and_token
    with_vcr_off do
      user_agent = "user-agent-string"
      response_body = File.read("#{TEST_ROOT}/fixtures/profile.txt")
      headers = {"User-Agent" => user_agent}

      WorkOS::SSO.stub(:user_agent, user_agent) do
        stub_request(:post, "https://api.workos.com/sso/token")
          .with(headers: headers, body: profile_and_token_request_body)
          .to_return(status: 200, body: response_body)

        profile_and_token = WorkOS::SSO.profile_and_token(**profile_and_token_args)
        assert_kind_of WorkOS::ProfileAndToken, profile_and_token

        expectation = {
          connection_id: "conn_01EMH8WAK20T42N2NBMNBCYHAG",
          connection_type: "OktaSAML",
          email: "demo@workos-okta.com",
          first_name: "WorkOS",
          id: "prof_01DRA1XNSJDZ19A31F183ECQW5",
          idp_id: "00u1klkowm8EGah2H357",
          last_name: "Demo",
          role: {
            slug: "admin"
          },
          roles: [{
            slug: "admin"
          }],
          groups: %w[Admins Developers],
          organization_id: "org_01FG53X8636WSNW2WEKB2C31ZB",
          custom_attributes: {
            license: "professional"
          },
          raw_attributes: {
            email: "demo@workos-okta.com",
            first_name: "WorkOS",
            id: "prof_01DRA1XNSJDZ19A31F183ECQW5",
            idp_id: "00u1klkowm8EGah2H357",
            last_name: "Demo",
            groups: %w[Admins Developers],
            license: "professional"
          }
        }

        assert_equal "01DVX6QBS3EG6FHY2ESAA5Q65X", profile_and_token.access_token
        assert_equal expectation, profile_and_token.profile.to_json
      end
    end
  end

  # profile_and_token - unprocessable request

  def test_profile_and_token_unprocessable_raises_exception_with_request_id
    with_vcr_off do
      user_agent = "user-agent-string"
      headers = {"User-Agent" => user_agent}

      WorkOS::SSO.stub(:user_agent, user_agent) do
        stub_request(:post, "https://api.workos.com/sso/token")
          .with(headers: headers, body: profile_and_token_request_body)
          .to_return(
            headers: {"X-Request-ID" => "request-id"},
            status: 422,
            body: {error: "some error", error_description: "some error description"}.to_json
          )

        err = assert_raises(WorkOS::UnprocessableEntityError) do
          WorkOS::SSO.profile_and_token(**profile_and_token_args)
        end
        assert_equal "Status 422, some error - request ID: request-id", err.message
      end
    end
  end

  def test_profile_and_token_unprocessable_has_proper_error_attributes
    with_vcr_off do
      user_agent = "user-agent-string"
      headers = {"User-Agent" => user_agent}

      WorkOS::SSO.stub(:user_agent, user_agent) do
        stub_request(:post, "https://api.workos.com/sso/token")
          .with(headers: headers, body: profile_and_token_request_body)
          .to_return(
            headers: {"X-Request-ID" => "request-id"},
            status: 422,
            body: {error: "some error", error_description: "some error description"}.to_json
          )

        error = begin
          WorkOS::SSO.profile_and_token(**profile_and_token_args)
        rescue WorkOS::UnprocessableEntityError => e
          e
        end

        assert_equal 422, error.http_status
        assert_equal "request-id", error.request_id
        assert_equal "some error", error.error
        assert error.message.include?("some error")
      end
    end
  end

  # profile_and_token - detailed field validation errors

  def test_profile_and_token_detailed_field_errors_raises_exception
    with_vcr_off do
      user_agent = "user-agent-string"
      headers = {"User-Agent" => user_agent}

      WorkOS::SSO.stub(:user_agent, user_agent) do
        stub_request(:post, "https://api.workos.com/sso/token")
          .with(headers: headers, body: profile_and_token_request_body)
          .to_return(
            headers: {"X-Request-ID" => "request-id"},
            status: 422,
            body: {
              message: "Validation failed",
              code: "invalid_request_parameters",
              errors: [
                {
                  field: "code",
                  code: "missing_required_parameter",
                  message: "The code parameter is required"
                }
              ]
            }.to_json
          )

        assert_raises(WorkOS::UnprocessableEntityError) do
          WorkOS::SSO.profile_and_token(**profile_and_token_args)
        end
      end
    end
  end

  def test_profile_and_token_detailed_field_errors_has_proper_attributes
    with_vcr_off do
      user_agent = "user-agent-string"
      headers = {"User-Agent" => user_agent}

      WorkOS::SSO.stub(:user_agent, user_agent) do
        stub_request(:post, "https://api.workos.com/sso/token")
          .with(headers: headers, body: profile_and_token_request_body)
          .to_return(
            headers: {"X-Request-ID" => "request-id"},
            status: 422,
            body: {
              message: "Validation failed",
              code: "invalid_request_parameters",
              errors: [
                {
                  field: "code",
                  code: "missing_required_parameter",
                  message: "The code parameter is required"
                }
              ]
            }.to_json
          )

        error = begin
          WorkOS::SSO.profile_and_token(**profile_and_token_args)
        rescue WorkOS::UnprocessableEntityError => e
          e
        end

        assert_equal 422, error.http_status
        assert_equal "request-id", error.request_id
        assert_equal "invalid_request_parameters", error.code
        refute_nil error.errors
        assert error.errors.include?("code: missing_required_parameter")
        assert error.message.include?("Validation failed")
        assert error.message.include?("(code: missing_required_parameter)")
      end
    end
  end

  # profile_and_token - expired code

  def test_profile_and_token_expired_code_raises_exception
    with_vcr_off do
      user_agent = "user-agent-string"

      WorkOS::SSO.stub(:user_agent, user_agent) do
        stub_request(:post, "https://api.workos.com/sso/token")
          .with(body: profile_and_token_request_body)
          .to_return(
            status: 400,
            headers: {"X-Request-ID" => "request-id"},
            body: {
              error: "invalid_grant",
              error_description: "The code '01DVX3C5Z367SFHR8QNDMK7V24' has expired or is invalid."
            }.to_json
          )

        err = assert_raises(WorkOS::InvalidRequestError) do
          WorkOS::SSO.profile_and_token(**profile_and_token_args)
        end
        assert_equal(
          "Status 400, error: invalid_grant, error_description: The code '01DVX3C5Z367SFHR8QNDMK7V24'" \
          " has expired or is invalid. - request ID: request-id",
          err.message
        )
      end
    end
  end

  def test_profile_and_token_expired_code_has_proper_error_attributes
    with_vcr_off do
      user_agent = "user-agent-string"

      WorkOS::SSO.stub(:user_agent, user_agent) do
        stub_request(:post, "https://api.workos.com/sso/token")
          .with(body: profile_and_token_request_body)
          .to_return(
            status: 400,
            headers: {"X-Request-ID" => "request-id"},
            body: {
              error: "invalid_grant",
              error_description: "The code '01DVX3C5Z367SFHR8QNDMK7V24' has expired or is invalid."
            }.to_json
          )

        error = begin
          WorkOS::SSO.profile_and_token(**profile_and_token_args)
        rescue WorkOS::InvalidRequestError => e
          e
        end

        assert_equal 400, error.http_status
        assert_equal "request-id", error.request_id
        assert_equal "invalid_grant", error.error
        assert_equal "The code '01DVX3C5Z367SFHR8QNDMK7V24' has expired or is invalid.", error.error_description
        assert error.message.include?("invalid_grant")
      end
    end
  end

  # list_connections

  def test_list_connections_with_no_options
    VCR.use_cassette "sso/list_connections/with_no_options" do
      connections = WorkOS::SSO.list_connections

      expected_metadata = {
        "after" => nil,
        "before" => "before_id"
      }

      assert_equal 6, connections.data.size
      assert_equal expected_metadata, connections.list_metadata
    end
  end

  def test_list_connections_with_connection_type
    VCR.use_cassette "sso/list_connections/with_connection_type" do
      connections = WorkOS::SSO.list_connections(
        connection_type: "OktaSAML"
      )

      assert_equal 10, connections.data.size
      assert_equal "OktaSAML", connections.data.first.connection_type
    end
  end

  def test_list_connections_with_domain
    VCR.use_cassette "sso/list_connections/with_domain" do
      connections = WorkOS::SSO.list_connections(
        domain: "foo-corp.com"
      )

      assert_equal 1, connections.data.size
    end
  end

  def test_list_connections_with_organization_id
    VCR.use_cassette "sso/list_connections/with_organization_id" do
      connections = WorkOS::SSO.list_connections(
        organization_id: "org_01F9293WD2PDEEV4Y625XPZVG7"
      )

      assert_equal 1, connections.data.size
      assert_equal "org_01F9293WD2PDEEV4Y625XPZVG7", connections.data.first.organization_id
    end
  end

  def test_list_connections_with_limit
    VCR.use_cassette "sso/list_connections/with_limit" do
      connections = WorkOS::SSO.list_connections(
        limit: 2
      )

      assert_equal 2, connections.data.size
    end
  end

  def test_list_connections_with_before
    VCR.use_cassette "sso/list_connections/with_before" do
      connections = WorkOS::SSO.list_connections(
        before: "conn_01FA3WGCWPCCY1V2FGES2FDNP7"
      )

      assert_equal 3, connections.data.size
    end
  end

  def test_list_connections_with_after
    VCR.use_cassette "sso/list_connections/with_after" do
      connections = WorkOS::SSO.list_connections(
        after: "conn_01FA3WGCWPCCY1V2FGES2FDNP7"
      )

      assert_equal 2, connections.data.size
    end
  end

  # get_connection

  def test_get_connection_with_valid_id
    VCR.use_cassette("sso/get_connection_with_valid_id") do
      connection = WorkOS::SSO.get_connection(
        id: "conn_01FA3WGCWPCCY1V2FGES2FDNP7"
      )

      assert_equal "conn_01FA3WGCWPCCY1V2FGES2FDNP7", connection.id
      assert_equal "OktaSAML", connection.connection_type
      assert_equal "Foo Corp", connection.name
      assert_equal "foo-corp.com", connection.domains.first[:domain]
    end
  end

  def test_get_connection_with_invalid_id
    VCR.use_cassette("sso/get_connection_with_invalid_id") do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::SSO.get_connection(id: "invalid")
      end
      assert_equal "Status 404, Not Found - request ID: ", err.message
    end
  end

  # delete_connection

  def test_delete_connection_with_valid_id
    VCR.use_cassette("sso/delete_connection_with_valid_id") do
      response = WorkOS::SSO.delete_connection(
        id: "conn_01EX55FRVN1V2PCA9YWTMZQMMQ"
      )

      assert_equal true, response
    end
  end

  def test_delete_connection_with_invalid_id
    VCR.use_cassette("sso/delete_connection_with_invalid_id") do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::SSO.delete_connection(id: "invalid")
      end
      assert_equal "Status 404, Not Found - request ID: ", err.message
    end
  end
end
