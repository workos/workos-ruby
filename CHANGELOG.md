# Changelog

## [7.1.0](https://github.com/workos/workos-ruby/compare/v7.0.0...v7.1.0) (2026-04-27)


### Features

* **generated:** update generated SDK from spec changes ([#465](https://github.com/workos/workos-ruby/issues/465)) ([6c145d2](https://github.com/workos/workos-ruby/commit/6c145d2bfec9af8fcffdc5ffe678f452ea925f22))


### Bug Fixes

* add ruby/setup-ruby to release-please workflow ([aa5ebd0](https://github.com/workos/workos-ruby/commit/aa5ebd0e26edc291f54d92b2f4681a224b0d3889))
* eagerly load configuration.rb to fix WorkOS.configure ([#467](https://github.com/workos/workos-ruby/issues/467)) ([eea391c](https://github.com/workos/workos-ruby/commit/eea391cd88015373fb89f3b8fbe1dda9c5cfedbe))
* remove stale URN-prefixed alias files breaking Zeitwerk ([#466](https://github.com/workos/workos-ruby/issues/466)) ([92b2aa5](https://github.com/workos/workos-ruby/commit/92b2aa5166e370bc8f9aaaee22626058d93521a5))
* update Gemfile.lock in release-please PR and bump action pins ([2aa0574](https://github.com/workos/workos-ruby/commit/2aa0574f3084e79af488c2125adbfc337604a3be))
* update Zeitwerk autoload for inflections.rb ([#460](https://github.com/workos/workos-ruby/issues/460)) ([4fa1332](https://github.com/workos/workos-ruby/commit/4fa1332f66c14e89c6df8d8d6af6ac8024824b15))

## [7.0.0](https://github.com/workos/workos-ruby/compare/v6.2.0...v7.0.0) (2026-04-20)

This is a major release that introduces a fully redesigned SDK architecture. The SDK is now **generated from the WorkOS OpenAPI spec**, bringing type safety, consistent interfaces, and improved developer ergonomics.

### High-Level Changes

- **Client-centric architecture**: The SDK now revolves around an instantiated `WorkOS::Client` rather than module-level service calls. All product areas are accessed through client methods (e.g., `client.organizations`, `client.user_management`, `client.sso`).

- **Generated request/response models**: Typed models replace raw hashes. Response models no longer inherit from `Hash` — use accessor methods instead of bracket notation.

- **Per-request overrides**: The new runtime supports `request_options:` for per-request API key, timeout, base URL, and retry overrides — useful for multi-tenant setups.

- **Minimum Ruby 3.3+**: The minimum Ruby version has been raised to 3.3.

- **Renamed services and methods**: Several top-level services were renamed (e.g., `WorkOS::Portal` → `client.admin_portal`, `WorkOS::MFA` → `client.multi_factor_auth`). Method signatures now use explicit keyword arguments.

- **Session management refactor**: AuthKit session sealing, refresh, and authentication flows were overhauled with a dedicated `SessionManager` on the client instance.

- **New capabilities**: Device code flow, public/PKCE clients, `auto_paging_each` pagination, and `last_response` observability on all responses.

### Migration Guide

For detailed instructions on updating your application, see the **[v7 Migration Guide](https://github.com/workos/workos-ruby/blob/main/docs/V7_MIGRATION_GUIDE.md)**.


## [6.2.0](https://github.com/workos/workos-ruby/compare/v6.1.0...v6.2.0) (2026-03-06)


### Features

* **user-management:** add directory_managed to OrganizationMembership ([#446](https://github.com/workos/workos-ruby/issues/446)) ([914d824](https://github.com/workos/workos-ruby/commit/914d824668b70950905d5db666978e9609c9f706))
* **user-management:** add invitation accept endpoint ([#448](https://github.com/workos/workos-ruby/issues/448)) ([b5b4da1](https://github.com/workos/workos-ruby/commit/b5b4da1c031bc5f688562fdc33506e03b769f650))


### Bug Fixes

* update renovate rules ([#443](https://github.com/workos/workos-ruby/issues/443)) ([f156c79](https://github.com/workos/workos-ruby/commit/f156c799e88269493104628760f94b8abaebf542))

## [6.1.0](https://github.com/workos/workos-ruby/compare/workos-v6.0.0...workos/v6.1.0) (2026-02-10)


### Features

* add support for totp_secret ([#300](https://github.com/workos/workos-ruby/issues/300)) ([c0a26bf](https://github.com/workos/workos-ruby/commit/c0a26bf745fb49ebaac7c5241e99d51188b886bb))
* Include Feature Flags decoded from the JWT in the payload of a Session ([#386](https://github.com/workos/workos-ruby/issues/386)) ([31a0e79](https://github.com/workos/workos-ruby/commit/31a0e7901247652182dcaad95e131357b93d0d71))
* **workos-ruby:** Add `connection` to `authorization_url` ([#78](https://github.com/workos/workos-ruby/issues/78)) ([c3a0e8e](https://github.com/workos/workos-ruby/commit/c3a0e8e4031a3ee888d925c11f1fd2fb152f0a16))


### Bug Fixes

* add `invitation_token` parameter to authentication methods ([#438](https://github.com/workos/workos-ruby/issues/438)) ([d24e3dc](https://github.com/workos/workos-ruby/commit/d24e3dc2995de26970415e4570a7ed810d432715))
