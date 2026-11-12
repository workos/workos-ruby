# workos-workload-identity-aws

AWS identity token provider for [WorkOS](https://workos.com) workload identity federation. With it, a workload on AWS calls the WorkOS API using a token STS issues for its IAM principal, and no API key is stored.

Use it with the [`workos`](https://rubygems.org/gems/workos) gem. This gem depends on the AWS SDK's STS client (`aws-sdk-sts`); the `workos` gem does not.

## Installation

```ruby
gem "workos"
gem "workos-workload-identity-aws"
```

## Usage

```ruby
require "workos"
require "workos-workload-identity-aws"

credentials = WorkOS::WorkloadIdentity::Credentials.new(
  client_id: "client_...",
  token_url: "https://.../oauth2/token",
  environment_id: "environment_...",
  identity_token_provider: WorkOS::WorkloadIdentity::AWS.aws_sts("https://api.workos.com", "us-east-1")
)

client = WorkOS::Client.new(credentials: credentials)
```

The first argument is the audience the token is requested for. It must match the audience of the trust rule on your WorkOS application. The second is the AWS region; leave it out to use the region the AWS SDK resolves (`AWS_REGION` or the shared config file). With no region, `aws_sts` raises.

Requirements on the AWS side:

- Outbound identity federation is enabled for the account.
- The workload's IAM principal is allowed to call `sts:GetWebIdentityToken`.

Each call makes one `GetWebIdentityToken` request with `RS256`, through the AWS SDK's default credential chain, on the regional STS endpoint. The provider keeps no cache and does not retry (the AWS SDK's own retries are turned off); the SDK does both.
