# frozen_string_literal: true

# @oagen-ignore-file
require "test_helper"
require "uri"

class SSOHelpersTest < Minitest::Test
  def setup
    @client = WorkOS::Client.new(api_key: "sk_test_sso", client_id: "client_001")
    @sso = @client.sso
  end

  # H14
  def test_get_authorization_url_returns_string
    url = @sso.get_authorization_url(
      redirect_uri: "https://app.example.com/cb",
      connection: "conn_001"
    )
    parsed = URI.parse(url)
    params = URI.decode_www_form(parsed.query).to_h
    assert_equal "/sso/authorize", parsed.path
    assert_equal "client_001", params["client_id"]
    assert_equal "conn_001", params["connection"]
    assert_equal "code", params["response_type"]
  end

  def test_get_authorization_url_serializes_provider_scopes_csv
    url = @sso.get_authorization_url(
      redirect_uri: "x",
      provider: "GoogleOAuth",
      provider_scopes: ["openid", "email"]
    )
    params = URI.decode_www_form(URI.parse(url).query).to_h
    assert_equal "openid,email", params["provider_scopes"]
  end

  def test_get_authorization_url_serializes_provider_query_params_json
    url = @sso.get_authorization_url(
      redirect_uri: "x",
      provider: "GoogleOAuth",
      provider_query_params: {"hd" => "example.com"}
    )
    params = URI.decode_www_form(URI.parse(url).query).to_h
    assert_equal({"hd" => "example.com"}, JSON.parse(params["provider_query_params"]))
  end

  # H15
  def test_get_authorization_url_with_pkce_appends_challenge
    url, verifier, state = @sso.get_authorization_url_with_pkce(
      redirect_uri: "x",
      connection: "conn_001"
    )
    params = URI.decode_www_form(URI.parse(url).query).to_h
    assert_equal "S256", params["code_challenge_method"]
    assert_equal WorkOS::PKCE.generate_code_challenge(verifier), params["code_challenge"]
    assert_equal state, params["state"]
  end

  # H16
  def test_get_profile_and_token_with_pkce_posts_pkce_grant
    stub = stub_request(:post, "https://api.workos.com/sso/token")
      .with(body: hash_including(
        "grant_type" => "authorization_code",
        "client_id" => "client_001",
        "code" => "code_xyz",
        "code_verifier" => "v_abc"
      ))
      .to_return(status: 200, body: '{"profile":{"id":"prof_1","connection_id":"c","connection_type":"OktaSAML","email":"x@y","first_name":null,"last_name":null,"groups":null,"organization_id":null,"raw_attributes":null,"role":null,"custom_attributes":null,"object":"profile","idp_id":null},"access_token":"a","oauth_tokens":null,"impersonator":null}')
    @sso.get_profile_and_token_with_pkce(code: "code_xyz", code_verifier: "v_abc")
    assert_requested(stub)
  end

  # H17
  def test_build_logout_url_returns_string_no_http
    url = @sso.build_logout_url(token: "tok_xyz")
    parsed = URI.parse(url)
    assert_equal "/sso/logout", parsed.path
    assert_equal "tok_xyz", URI.decode_www_form(parsed.query).to_h["token"]
  end
end
