# WorkOS Ruby Library

The WorkOS Ruby SDK provides convenient access to the WorkOS API from applications written in Ruby.

## Documentation

- [Ruby SDK documentation](https://docs.workos.com/sdk/ruby)
- [API reference](https://workos.com/docs/reference/client-libraries)

## Installation

Install the package with:

```sh
gem install workos
```

If you're using Bundler to manage your application's gems, add the WorkOS gem to your Gemfile:

```ruby
source "https://rubygems.org"

gem "workos"
```

## Configuration

To use the library, provide your WorkOS API key as `WORKOS_API_KEY` and, for AuthKit and SSO flows, your client ID as `WORKOS_CLIENT_ID`:

```sh
WORKOS_API_KEY=sk_test_123 WORKOS_CLIENT_ID=client_123 ruby app.rb
```

Or configure the SDK in an initializer:

```ruby
# /config/initializers/workos.rb

require "workos"
require "workos/configuration"

WorkOS.configure do |config|
  config.api_key = ENV.fetch("WORKOS_API_KEY")
  config.client_id = ENV["WORKOS_CLIENT_ID"]
  config.timeout = 120
  config.logger = Logger.new($stdout)
  config.log_level = :info
end

client = WorkOS.client
```

## Client patterns

### Singleton (recommended for most apps)

```ruby
WorkOS.configure do |config|
  config.api_key = ENV.fetch("WORKOS_API_KEY")
  config.client_id = ENV["WORKOS_CLIENT_ID"]
end

WorkOS.client.organizations.list_organizations
```

### Multi-tenant (one client per API key)

```ruby
tenant_a = WorkOS::Client.new(api_key: "sk_tenant_a", client_id: "client_a")
tenant_b = WorkOS::Client.new(api_key: "sk_tenant_b", client_id: "client_b")

tenant_a.organizations.list_organizations
tenant_b.organizations.list_organizations
```

### Public / PKCE (browser, mobile, CLI)

```ruby
public_client = WorkOS::PublicClient.create(client_id: "client_123")
url, verifier, state = public_client.user_management.get_authorization_url_with_pkce(
  redirect_uri: "https://example.com/callback"
)
```

### Fork safety (Puma / Unicorn)

The SDK caches persistent connections per fiber. After forking, call
`WorkOS.reset_client` (or `client.shutdown`) to close inherited sockets:

```ruby
# config/puma.rb
on_worker_boot { WorkOS.reset_client }
```

## Per-request options

Every API call accepts `request_options:` for per-call overrides:

```ruby
organization = WorkOS.client.organizations.get_organization(
  id: "org_123",
  request_options: {
    timeout: 10,
    extra_headers: {"X-Request-Source" => "admin"},
    idempotency_key: "org-create-123"
  }
)
```

`Idempotency-Key` is only sent when you provide `request_options[:idempotency_key]`, or when the SDK retries a mutating request after a transient failure.

## Usage Examples

### List organizations

```ruby
organizations = WorkOS.client.organizations.list_organizations(limit: 10)

organizations.data.each do |organization|
  puts "#{organization.id}: #{organization.name}"
end
```

### Get an organization

```ruby
organization = WorkOS.client.organizations.get_organization(id: "org_123")
puts organization.name
```

### Create a user

```ruby
user = WorkOS.client.user_management.create_user(
  email: "marceline@example.com",
  first_name: "Marceline",
  last_name: "Abadeer"
)

puts user.id
```

### Verify a webhook

```ruby
payload = request.body.read
signature = request.env.fetch("HTTP_WORKOS_SIGNATURE")
secret = ENV.fetch("WORKOS_WEBHOOK_SECRET")

event = WorkOS.client.webhooks.construct_event(
  payload: payload,
  sig_header: signature,
  secret: secret
)

puts event.event
```

## Pagination

List endpoints return `WorkOS::Types::ListStruct`, which supports inspecting pagination metadata or iterating through every record automatically.

```ruby
users = WorkOS.client.user_management.list_users(limit: 100)

users.auto_paging_each do |user|
  puts user.email
end
```

You can also iterate page by page:

```ruby
users.each_page do |page|
  puts page.list_metadata
end
```

## Error Handling

The SDK raises typed errors for API and transport failures.

```ruby
begin
  WorkOS.client.organizations.get_organization(id: "org_123")
rescue WorkOS::APIError => e
  warn "#{e.class}: #{e.message}"
  warn "status=#{e.http_status} request_id=#{e.request_id} code=#{e.code}"
end
```

## SDK Versioning

For our SDKs WorkOS follows a Semantic Versioning ([SemVer](https://semver.org/)) process where all releases will have a version X.Y.Z (like 1.0.0) pattern wherein Z would be a bug fix (e.g., 1.0.1), Y would be a minor release (1.1.0) and X would be a major release (2.0.0). We permit any breaking changes to only be released in major versions and strongly recommend reading changelogs before making any major version upgrades.

## Beta Releases

WorkOS has features in Beta that can be accessed via Beta releases. We would love for you to try these
and share feedback with us before these features reach general availability (GA). To install a Beta version,
please follow the [installation steps](#installation) above using the Beta release version.

> Note: there can be breaking changes between Beta versions. Therefore, we recommend pinning the package version to a
> specific version. This way you can install the same version each time without breaking changes unless you are
> intentionally looking for the latest Beta version.

We highly recommend keeping an eye on when the Beta feature you are interested in goes from Beta to stable so that you
can move to using the stable version.

## More Information

- [Ruby SDK documentation](https://docs.workos.com/sdk/ruby)
- [Single Sign-On Guide](https://workos.com/docs/sso/guide)
- [Directory Sync Guide](https://workos.com/docs/directory-sync/guide)
- [Admin Portal Guide](https://workos.com/docs/admin-portal/guide)
