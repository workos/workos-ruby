# workos-workload-identity-gcp

Google Cloud identity token provider for [WorkOS](https://workos.com) workload identity federation. With it, a workload on Compute Engine, GKE, Cloud Run or Cloud Functions calls the WorkOS API using the identity token of its service account, and no API key is stored.

Use it with the [`workos`](https://rubygems.org/gems/workos) gem. This gem has no runtime dependencies.

## Installation

```ruby
gem "workos"
gem "workos-workload-identity-gcp"
```

## Usage

```ruby
require "workos"
require "workos-workload-identity-gcp"

credentials = WorkOS::WorkloadIdentity::Credentials.new(
  client_id: "client_...",
  token_url: "https://.../oauth2/token",
  environment_id: "environment_...",
  identity_token_provider: WorkOS::WorkloadIdentity::GCP.gcp_metadata("https://api.workos.com")
)

client = WorkOS::Client.new(credentials: credentials)
```

The argument is the audience the token is requested for. It must match the audience of the trust rule on your WorkOS application.

Each call makes one HTTP GET to the metadata server (`metadata.google.internal`), for the default service account. The provider keeps no cache and does not retry; the SDK does both.
