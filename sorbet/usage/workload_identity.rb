# frozen_string_literal: true
# typed: strict

# @oagen-ignore-file
#
# Type-checked by `srb tc`, never run. lib/ carries no `# typed:` sigil, so
# nothing there exercises the hand-maintained signatures in rbi/. This file
# does: every line must type-check against them, the way an application
# that uses Sorbet would call them. If a signature changes in a way that
# breaks such a caller, `srb tc` fails here.

provider = WorkOS::WorkloadIdentity.token_file("/var/run/secrets/workos/token")
T.assert_type!(provider.call, String)
T.assert_type!(WorkOS::WorkloadIdentity.token_env("WORKOS_IDENTITY_TOKEN").call, String)

credentials = WorkOS::WorkloadIdentity::Credentials.new(
  identity_token_provider: provider,
  client_id: "client_123",
  token_url: "https://auth.example.test/oauth2/token",
  environment_id: "environment_123",
  scope: "widgets:read"
)
T.assert_type!(credentials.client_id, String)
T.assert_type!(credentials.scope, T.nilable(String))

snapshot = credentials.resolve(timeout: 5)
T.assert_type!(snapshot, WorkOS::CredentialSnapshot)
T.assert_type!(snapshot.headers, T::Hash[String, String])
T.assert_type!(snapshot.recoverable, T::Boolean)
T.assert_type!(snapshot.to_s, String)
credentials.invalidate(snapshot.generation)
# What a custom credentials object returns from its own `resolve`.
WorkOS::CredentialSnapshot.new(headers: {"Authorization" => "Bearer token"}, generation: 1, recoverable: false)

client = WorkOS::Client.new(credentials: credentials, timeout: 10, max_retries: 1, log_level: :info)
T.assert_type!(client.base_url, String)
T.assert_type!(client.api_key, T.nilable(String))
T.assert_type!(client.client_id, T.nilable(String))
T.assert_type!(client.timeout, Numeric)
T.assert_type!(client.max_retries, Integer)
T.assert_type!(client.log_level, T.nilable(Symbol))
T.assert_type!(client.jwt_issuer, T.nilable(T.any(String, T::Array[String])))
T.assert_type!(
  client.get_request(path: "/widgets", params: {"limit" => 10}, request_options: {api_key: "sk_test_123"}),
  Net::HTTP::Get
)
T.assert_type!(client.put_request(path: "/widgets/1", body: {name: "b"}), Net::HTTP::Put)
T.assert_type!(client.patch_request(path: "/widgets/1", body: nil), Net::HTTP::Patch)
T.assert_type!(client.delete_request(path: "/widgets/1"), Net::HTTP::Delete)
T.assert_type!(WorkOS::BaseClient.retry_delay(nil, 1, Random.new), Float)
T.assert_type!(WorkOS::BaseClient::DEFAULT_TIMEOUT, Integer)
T.assert_type!(client.request(method: :get, path: "/widgets", params: {limit: 10}), Net::HTTPResponse)
T.assert_type!(
  client.execute_request(request: client.post_request(path: "/widgets", auth: true, body: {name: "a"})),
  Net::HTTPResponse
)
client.shutdown

WorkOS::Client.new(api_key: "sk_test_123", jwt_issuer: ["https://issuer.example.test"])
T.assert_type!(WorkOS::StaticKeyCredentials.new("sk_test_123").resolve, WorkOS::CredentialSnapshot)

begin
  credentials.resolve
rescue WorkOS::WorkloadIdentityError => e
  T.assert_type!(e.code, String)
  T.assert_type!(e.description, String)
  T.assert_type!(e.hint, String)
end

# The provider gems: each returns something `Credentials` accepts.
[
  WorkOS::WorkloadIdentity::GitHubActions.github_actions("https://api.workos.com"),
  WorkOS::WorkloadIdentity::GCP.gcp_metadata("https://api.workos.com"),
  WorkOS::WorkloadIdentity::AWS.aws_sts("https://api.workos.com"),
  WorkOS::WorkloadIdentity::AWS.aws_sts("https://api.workos.com", "us-east-1")
].each do |platform_provider|
  T.assert_type!(platform_provider.call, String)
  WorkOS::WorkloadIdentity::Credentials.new(identity_token_provider: platform_provider)
end
