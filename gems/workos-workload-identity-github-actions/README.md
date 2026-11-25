# workos-workload-identity-github-actions

GitHub Actions identity token provider for [WorkOS](https://workos.com) workload identity federation. With it, a workflow calls the WorkOS API using the OIDC token GitHub issues to the job, and no API key is stored in the repository.

Use it with the [`workos`](https://rubygems.org/gems/workos) gem. This gem has no runtime dependencies.

## Installation

```ruby
gem "workos"
gem "workos-workload-identity-github-actions"
```

## Usage

Grant the job permission to request an OIDC token:

```yaml
permissions:
  id-token: write
```

Then build the client from workload identity credentials:

```ruby
require "workos"
require "workos-workload-identity-github-actions"

credentials = WorkOS::WorkloadIdentity::Credentials.new(
  client_id: "client_...",
  token_url: "https://.../oauth2/token",
  environment_id: "environment_...",
  identity_token_provider: WorkOS::WorkloadIdentity::GitHubActions.github_actions("https://api.workos.com")
)

client = WorkOS::Client.new(credentials: credentials)
```

The argument is the audience the token is requested for. It must match the audience of the trust rule on your WorkOS application.

Each call makes one HTTP GET to the endpoint GitHub provides in `ACTIONS_ID_TOKEN_REQUEST_URL`. The provider keeps no cache and does not retry; the SDK does both.
