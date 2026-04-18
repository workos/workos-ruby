# WorkOS Ruby SDK v7 Migration Guide

This guide covers the changes required to migrate from the v6 Ruby SDK to the next major release of `workos`.

The biggest change is architectural: the SDK is now centered around an instantiated `WorkOS::Client` with client-scoped service accessors, generated request/response models, and a hand-maintained instance-scoped HTTP runtime.

## Quick Start

1. Upgrade to Ruby 3.3 or newer.
2. Upgrade the gem:

   ```ruby
   gem "workos", "~> 7.0"
   ```

3. Replace module-style service calls with a `WorkOS::Client` or `WorkOS.client`:

   ```ruby
   require "workos"
   require "workos/configuration"

   WorkOS.configure do |config|
     config.api_key = ENV.fetch("WORKOS_API_KEY")
     config.client_id = ENV["WORKOS_CLIENT_ID"]
   end

   client = WorkOS.client
   ```

4. Update renamed services, changed method signatures, and changed return types.
5. Re-run your tests and verify auth, session, SSO, webhook, and pagination flows end-to-end.

---

## Ruby and Dependency Requirements

### Minimum Ruby version is now 3.3+

The new SDK requires Ruby 3.3 or newer.

### Runtime dependencies changed

- `zeitwerk` is now required.
- `logger` is now a runtime dependency.
- `encryptor` was removed from the main gemspec.

---

## Biggest Conceptual Changes

### 1. The SDK now revolves around an instantiated client

Before:

```ruby
WorkOS.configure do |config|
  config.key = ENV["WORKOS_API_KEY"]
end

organizations = WorkOS::Organizations.list_organizations
```

After:

```ruby
WorkOS.configure do |config|
  config.api_key = ENV.fetch("WORKOS_API_KEY")
  config.client_id = ENV["WORKOS_CLIENT_ID"]
end

client = WorkOS.client
organizations = client.organizations.list_organizations
```

`WorkOS.configure` still exists, but the configuration object changed and the intended integration style is now a client instance.

### 2. Most product areas are now accessed through client methods

Instead of calling module methods like `WorkOS::Organizations.list_organizations` or `WorkOS::Portal.generate_link`, you now call lazy client accessors:

- `client.organizations`
- `client.user_management`
- `client.sso`
- `client.directory_sync`
- `client.multi_factor_auth`
- `client.admin_portal`
- `client.audit_logs`
- `client.authorization`
- `client.webhooks`
- `client.passwordless`

### 3. The runtime is instance-scoped and supports per-request overrides

The new runtime stores credentials, base URL, timeout, retry settings, and service wiring on the client instance.

Methods now consistently accept:

```ruby
request_options: {
  timeout: 10,
  base_url: "https://api.workos.com",
  max_retries: 1,
  idempotency_key: "org-create-123",
  extra_headers: {"X-Request-Source" => "admin"}
}
```

If your integration depended on global mutable config being the source of truth for requests, review that code carefully.

### 4. AuthKit and session helpers moved to client-based helpers

Before:

```ruby
session = WorkOS::UserManagement.load_sealed_session(
  client_id: client_id,
  session_data: session_data,
  cookie_password: cookie_password
)
```

After:

```ruby
client = WorkOS::Client.new(
  api_key: ENV.fetch("WORKOS_API_KEY"),
  client_id: ENV.fetch("WORKOS_CLIENT_ID")
)

session = client.session_manager.load(
  seal_data: session_data,
  cookie_password: cookie_password
)
```

If you use AuthKit session sealing, refresh, PKCE, or logout helpers, review those flows carefully.

---

## Breaking Changes by Area

### Client bootstrap and configuration

#### Configuration field names changed

Before:

```ruby
WorkOS.configure do |config|
  config.key = ENV["WORKOS_API_KEY"]
  config.api_hostname = "api.workos.com"
end
```

After:

```ruby
WorkOS.configure do |config|
  config.api_key = ENV.fetch("WORKOS_API_KEY")
  config.base_url = "https://api.workos.com"
  config.client_id = ENV["WORKOS_CLIENT_ID"]
  config.timeout = 30
  config.max_retries = 2
end
```

#### Direct module-style service access is no longer the default integration pattern

Code like this should be removed:

```ruby
WorkOS::Organizations.list_organizations
WorkOS::Portal.generate_link(...)
WorkOS::MFA.verify_challenge(...)
WorkOS::UserManagement.authenticate_with_code(...)
```

Use the client methods instead:

```ruby
client.organizations.list_organizations
client.admin_portal.generate_link(...)
client.multi_factor_auth.verify_challenge(...)
client.user_management.authenticate_with_code(...)
```

### Service renames and access patterns

#### Several top-level service names changed

Update these references:

- `WorkOS::Portal` -> `client.admin_portal`
- `WorkOS::MFA` -> `client.multi_factor_auth`
- `WorkOS::Organizations` -> `client.organizations`
- `WorkOS::UserManagement` -> `client.user_management`
- `WorkOS::DirectorySync` -> `client.directory_sync`
- `WorkOS::AuditLogs` -> `client.audit_logs`

#### Non-spec helpers are still available, but they moved behind the client

Helpers for PKCE, public clients, passwordless, vault, and session management still exist, but they are no longer organized the same way as the v5 surface.

Examples:

```ruby
client.session_manager
client.passwordless
client.pkce
WorkOS::PublicClient.create(client_id: "client_123")
```

### Method signatures

#### Many methods moved from option hashes or old keywords to explicit named arguments

Before:

```ruby
WorkOS::Organizations.list_organizations(after: "org_123", limit: 25)
WorkOS::Organizations.update_organization(organization: "org_123", name: "Acme")
```

After:

```ruby
client.organizations.list_organizations(after: "org_123", limit: 25)
client.organizations.update_organization(id: "org_123", name: "Acme")
```

Notable signature changes:

- `update_organization(organization: ...)` -> `update_organization(id: ...)`
- mutating calls now take `request_options:` instead of ad hoc transport arguments like `idempotency_key:`
- auth helpers infer `client_id` and `client_secret` from the client instead of requiring them on every call

#### Auth helper signatures changed substantially

Before:

```ruby
response = WorkOS::UserManagement.authenticate_with_code(
  code: code,
  client_id: client_id,
  ip_address: ip_address,
  user_agent: user_agent,
  session: { seal_session: true, cookie_password: cookie_password }
)
```

After:

```ruby
response = client.user_management.authenticate_with_code(
  code: code,
  ip_address: ip_address,
  device_id: device_id,
  user_agent: user_agent,
  request_options: {}
)
```

Review all usages of:

- `authenticate_with_code`
- `authenticate_with_password`
- `authenticate_with_refresh_token`
- `authenticate_with_magic_auth`
- `authenticate_with_email_verification`

#### Authorization URL helpers were renamed

Before:

```ruby
WorkOS::UserManagement.authorization_url(...)
WorkOS::SSO.authorization_url(...)
```

After:

```ruby
client.user_management.get_authorization_url(...)
client.user_management.get_authorization_url_with_pkce(...)
client.sso.get_authorization_url(...)
client.sso.get_authorization_url_with_pkce(...)
```

### Return types and models

#### Some methods now return typed models instead of primitives

Before:

```ruby
link = WorkOS::Portal.generate_link(
  intent: "sso",
  organization: "org_123"
)
```

After:

```ruby
response = client.admin_portal.generate_link(
  organization: "org_123",
  intent: "sso"
)

link = response.link
```

If your code expects a raw string or hash, check the return type again.

#### Some auth and MFA model class names changed

Examples:

- `WorkOS::AuthenticationResponse` -> `WorkOS::AuthenticateResponse`
- `WorkOS::Factor` -> `WorkOS::AuthenticationFactor`
- `WorkOS::Challenge` -> `WorkOS::AuthenticationChallenge`
- `WorkOS::VerifyChallenge` -> `WorkOS::AuthenticationChallengeVerifyResponse`

If your code imports, type-checks, or pattern matches on these classes, update those references.

### Error handling

#### Error classes are still typed, but the base class contract changed

Before:

```ruby
begin
  WorkOS::Organizations.get_organization(id: "org_123")
rescue WorkOS::TimeoutError => e
  warn e.retry_after
  warn e.data
end
```

After:

```ruby
begin
  client.organizations.get_organization(id: "org_123")
rescue WorkOS::APIConnectionError => e
  warn e.message
  warn e.request_id
  warn e.code
  warn e.body.inspect
end
```

Important differences:

- transport failures now raise `WorkOS::APIConnectionError`
- the old `WorkOS::TimeoutError` is no longer part of the new error surface
- the old extra fields like `retry_after`, `errors`, `error_description`, and `data` are not exposed the same way

If your code rescues specific exception types or reads fields from exceptions, review every rescue path.

### Pagination

#### `ListStruct` is still the pagination wrapper, but it is more capable now

Before:

```ruby
result = WorkOS::Organizations.list_organizations
result.data
result.list_metadata
```

After:

```ruby
result = client.organizations.list_organizations(limit: 100)

result.data
result.list_metadata
result.auto_paging_each do |organization|
  puts organization.id
end
```

This is mostly an improvement, but if you implemented your own pagination assumptions around the old response shape, test those code paths again.

### AuthKit sessions and cookies

#### Session management moved out of `UserManagement` and into `SessionManager`

Before:

```ruby
session = WorkOS::UserManagement.load_sealed_session(
  client_id: client_id,
  session_data: session_data,
  cookie_password: cookie_password
)
```

After:

```ruby
session = client.session_manager.load(
  seal_data: session_data,
  cookie_password: cookie_password
)
```

Refresh and authenticate helpers also moved:

```ruby
client.session_manager.authenticate(...)
client.session_manager.refresh(...)
```

If your app relies on session sealing or cookie refresh behavior, verify those flows carefully in integration tests.
