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

#### Response models no longer inherit from `Hash`

In v6, `WorkOS::DirectoryUser`, `WorkOS::DirectoryGroup`, and other models inherited from an internal `DeprecatedHashWrapper < Hash`. That meant an instance was simultaneously a model and a `Hash`, which produced confusing behavior like this (see [#316](https://github.com/workos/workos-ruby/issues/316)):

```ruby
user.is_a?(WorkOS::DirectoryUser)           # => true
user.is_a?(Hash)                            # => true  (v6)
user.to_hash.is_a?(WorkOS::DirectoryUser)   # => true  (v6 — returned self)
user.to_h                                   # => "{...}"  (v6 — returned a JSON string)
user[:id]                                   # => "user_123" with a deprecation warning
```

In v7, models are plain classes that `include WorkOS::HashProvider`. They are no longer `Hash` instances:

```ruby
user.is_a?(WorkOS::DirectoryUser)  # => true
user.is_a?(Hash)                   # => false
user.to_h                          # => { id: "user_123", email: "...", ... }  (real Hash)
user.to_h.is_a?(Hash)              # => true
user.to_json                       # => '{"id":"user_123",...}'
user[:id]                          # => NoMethodError
user.to_hash                       # => NoMethodError
```

Update call sites accordingly:

- Replace `user[:attr]` with the accessor method (`user.attr`).
- Replace `user.to_hash` with `user.to_h`.
- If you relied on passing a model into `**splat` or `Hash#merge` (which used the implicit `to_hash` coercion), call `.to_h` explicitly: `merge(user.to_h)`, `some_method(**user.to_h)`.
- If you called `.to_h` and expected a JSON string, use `.to_json` instead.
- Any `rescue`/log/assertion that inspects a model with `is_a?(Hash)` needs to be updated.

The `DeprecatedHashWrapper` class and its deprecation warnings have been removed.

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

Session management was one of the largest refactors in v7. The old `WorkOS::Session`, the `session:` kwarg on `authenticate_with_*`, and the class-level `seal_data` / `unseal_data` helpers were all replaced by a dedicated `WorkOS::SessionManager` on the client. The behavior is similar, but the surface area, return types, parameter names, and reason strings all changed.

If your application seals session cookies, refreshes access tokens, or decodes the access-token JWT, every one of these call sites needs to be updated.

#### Sealing a cookie from an authentication response

In v6, you asked `authenticate_with_*` to seal the cookie for you:

```ruby
response = WorkOS::UserManagement.authenticate_with_code(
  code: code,
  client_id: client_id,
  session: { seal_session: true, cookie_password: cookie_password }
)

response.sealed_session # => "..."
```

In v7, the `session:` kwarg has been removed from **every** `authenticate_with_*` helper. Seal the cookie yourself after the authenticate call:

```ruby
response = client.user_management.authenticate_with_code(code: code)

sealed = client.session_manager.seal_session_from_auth_response(
  access_token: response.access_token,
  refresh_token: response.refresh_token,
  cookie_password: cookie_password,
  user: response.user,
  impersonator: response.impersonator
)
```

This applies to all of:

- `authenticate_with_code`
- `authenticate_with_password`
- `authenticate_with_refresh_token`
- `authenticate_with_magic_auth`
- `authenticate_with_email_verification`
- `authenticate_with_totp`
- `authenticate_with_organization_selection`
- `authenticate_with_device_code`

#### Loading a session from a sealed cookie

Before:

```ruby
session = WorkOS::UserManagement.load_sealed_session(
  client_id: client_id,
  session_data: session_data,
  cookie_password: cookie_password,
  encryptor: custom_encryptor # optional
)
```

After:

```ruby
session = client.session_manager.load(
  seal_data: session_data,
  cookie_password: cookie_password
)
```

Notable changes:

- The kwarg is renamed from `session_data:` to `seal_data:`.
- `client_id` is no longer passed per-call; it is read from the client instance.
- A custom `encryptor:` is now supplied when the manager is created, not on `load`:

  ```ruby
  client.session_manager(encryptor: custom_encryptor)
  # or, for full control:
  WorkOS::SessionManager.new(client, encryptor: custom_encryptor)
  ```

#### Authenticating a loaded session

The return type changed from a `Hash` to a typed result object. **Any code that reads `result[:authenticated]` or `result[:reason]` needs to be updated.**

Before:

```ruby
result = session.authenticate

result[:authenticated]    # => true / false
result[:reason]           # => 'INVALID_SESSION_COOKIE' (uppercase string)
result[:session_id]
result[:feature_flags]
```

After:

```ruby
result = session.authenticate

case result
when WorkOS::SessionManager::AuthSuccess
  result.authenticated    # => true
  result.session_id
  result.organization_id
  result.role
  result.roles
  result.permissions
  result.entitlements
  result.feature_flags
  result.user
  result.impersonator
when WorkOS::SessionManager::AuthError
  result.authenticated    # => false
  result.reason           # => "invalid_session_cookie" (lowercase string)
end
```

Additional behavioral changes:

- **Reason strings are now lowercase.** `'NO_SESSION_COOKIE_PROVIDED'` → `"no_session_cookie_provided"`, `'INVALID_SESSION_COOKIE'` → `"invalid_session_cookie"`, `'INVALID_JWT'` → `"invalid_jwt"`. These are exposed as constants on `WorkOS::SessionManager` (`NO_SESSION_COOKIE_PROVIDED`, `INVALID_SESSION_COOKIE`, `INVALID_JWT`) — prefer the constants over string literals.
- **`claim_extractor` semantics changed.** In v6 the block's returned Hash was merged flat into the result Hash. In v7 the returned Hash is stored as `custom_claims` on `AuthSuccess` and accessed via `#[]` or via dynamic readers:

  ```ruby
  result = session.authenticate do |decoded_jwt|
    { tenant_id: decoded_jwt["tenant_id"] }
  end

  result[:tenant_id]   # => "tnt_123"
  result.tenant_id     # => "tnt_123"
  result.to_h[:tenant_id]
  ```

  The extractor **must** return a Hash and **must not** overwrite reserved keys (`authenticated`, `session_id`, `organization_id`, `role`, `roles`, `permissions`, `entitlements`, `user`, `impersonator`, `feature_flags`); doing either raises `ArgumentError`.

#### Refreshing a loaded session

The return shape was flattened and the option-hash parameter style was replaced with keyword arguments.

Before:

```ruby
result = session.refresh(
  cookie_password: cookie_password,
  organization_id: "org_123"
)

result[:authenticated]
result[:sealed_session]
result[:session].user            # nested AuthenticationResponse
result[:session].sealed_session
result[:reason]
```

After:

```ruby
result = session.refresh(
  organization_id: "org_123",
  cookie_password: cookie_password # optional; defaults to the password used at load
)

case result
when WorkOS::SessionManager::RefreshSuccess
  result.sealed_session     # new sealed cookie to write back to the browser
  result.session_id
  result.organization_id
  result.role
  result.roles
  result.permissions
  result.entitlements
  result.user
  result.impersonator
  result.feature_flags
when WorkOS::SessionManager::RefreshError
  result.authenticated      # => false
  result.reason
end
```

The nested `result[:session]` field is gone; the fields that used to live on that inner `AuthenticationResponse` are now exposed directly on `RefreshSuccess`. `session.refresh` also updates the `Session`'s internal `seal_data` / `cookie_password` in place, so a subsequent `session.authenticate` will use the refreshed token without reconstructing the `Session`.

For call sites that don't need a long-lived `Session` object, `SessionManager` also exposes inline helpers:

```ruby
client.session_manager.authenticate(seal_data: session_data, cookie_password: cookie_password)
client.session_manager.refresh(seal_data: session_data, cookie_password: cookie_password)
```

#### Building a logout URL

Before:

```ruby
url = session.get_logout_url(return_to: "https://example.com")
# or, if you only had the session_id:
url = WorkOS::UserManagement.get_logout_url(session_id: sid)
```

After:

```ruby
url = session.get_logout_url(return_to: "https://example.com")
# or, via the UserManagement service:
url = client.user_management.get_logout_url(session_id: sid, return_to: "https://example.com")
```

`Session#get_logout_url` now calls `authenticate` internally to extract the `session_id` and raises `WorkOS::Error` (instead of a plain `RuntimeError`) if authentication fails.

#### Raw seal / unseal helpers

The class methods `WorkOS::Session.seal_data` and `WorkOS::Session.unseal_data` were removed. Use the instance methods on `SessionManager` instead:

```ruby
# Before
sealed = WorkOS::Session.seal_data(payload, key)
WorkOS::Session.unseal_data(sealed, key)

# After
sealed = client.session_manager.seal_data(payload, key)
client.session_manager.unseal_data(sealed, key)
```

A custom encryptor passed to `client.session_manager(encryptor: ...)` is used by these helpers as well.

#### Deprecations to clean up

- `WorkOS::SessionManager::SEAL_VERSION` is deprecated in favor of `WorkOS::Encryptors::AesGcm::SEAL_VERSION`. Update any code reading the constant off the manager.
- `WorkOS::Session.new(...)` is still callable but its constructor signature changed (`Session.new(manager, seal_data:, cookie_password:)`). Prefer `client.session_manager.load(...)` — direct instantiation is no longer part of the public contract.

If your app relies on session sealing or cookie refresh behavior, verify those flows carefully in integration tests.
