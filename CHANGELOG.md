# Changelog

## [9.4.0](https://github.com/workos/workos-ruby/compare/v9.3.0...v9.4.0) (2026-07-02)


### Features

* **generated:** AdminPortal, Authorization, Webhooks, UserManagement, AuditLogs (batch 08085e9d) ([#510](https://github.com/workos/workos-ruby/issues/510)) ([fa3558b](https://github.com/workos/workos-ruby/commit/fa3558beed81c97dfc366bb188e5c8be7fa7f1e2))
* **generated:** Pipes (batch 77e46600) ([#508](https://github.com/workos/workos-ruby/issues/508)) ([aded437](https://github.com/workos/workos-ruby/commit/aded437bb7fbc20e5e3506cca193f1c619c4584b))
* **pipes:** Add Pipes operations and models ([#512](https://github.com/workos/workos-ruby/issues/512)) ([e371582](https://github.com/workos/workos-ruby/commit/e371582fad5a78f03c8ef8783e507fd2f418b6c6))
* **user_management:** Add user management operations and models ([#513](https://github.com/workos/workos-ruby/issues/513)) ([932bd29](https://github.com/workos/workos-ruby/commit/932bd291a88b569aeac4b3944239374ea781c41b))


### Bug Fixes

* **user_management:** Update user management API surface ([#513](https://github.com/workos/workos-ruby/issues/513)) ([932bd29](https://github.com/workos/workos-ruby/commit/932bd291a88b569aeac4b3944239374ea781c41b))

## [9.3.0](https://github.com/workos/workos-ruby/compare/v9.2.0...v9.3.0) (2026-06-30)

* [#504](https://github.com/workos/workos-ruby/pull/504) fix(generated): regenerate from spec

  **Fixes**
  * **[organization_membership](https://workos.com/docs/reference/authkit/organization-membership)**:
    * Added `roles` to organization membership models

## [9.2.0](https://github.com/workos/workos-ruby/compare/v9.1.0...v9.2.0) (2026-06-18)

- [#501](https://github.com/workos/workos-ruby/pull/501) feat(generated)!: regenerate from spec (12 changes)

  **Features**
  - **[authorization](https://workos.com/docs/reference/fga)**:
    - Added model `ReplaceGroupRoleAssignmentEntry`
    - Added model `ReplaceGroupRoleAssignments`
    - Added model `DeleteGroupRoleAssignmentsByCriteria`
    - Added endpoint `POST /authorization/groups/{group_id}/role_assignments`
    - Added endpoint `PUT /authorization/groups/{group_id}/role_assignments`
    - Added endpoint `DELETE /authorization/groups/{group_id}/role_assignments`
    - Added endpoint `GET /authorization/groups/{group_id}/role_assignments/{role_assignment_id}`
    - Added endpoint `DELETE /authorization/groups/{group_id}/role_assignments/{role_assignment_id}`
  - **[client](https://workos.com/docs/reference)**:
    - Added model `ClientApiToken`
    - Added model `ClientApiTokenResponse`
    - Added service `Client`
  - **[connect](https://workos.com/docs/reference/workos-connect/standalone)**:
    - Added `auth_method` to `ConnectedAccount`
    - Added `api_key_last_4` to `ConnectedAccount`
    - Added enum `ConnectedAccountAuthMethod`
  - **[groups](https://workos.com/docs/reference/groups)**:
    - Added model `CreateGroupRoleAssignment`
    - Added model `GroupRoleAssignment`
    - Added model `GroupRoleAssignmentList`
    - Added model `GroupRoleAssignmentResource`
  - **[organization_membership](https://workos.com/docs/reference/authkit/organization-membership)**:
    - Added model `UserOrganizationMembershipList`
    - Added model `UserOrganizationMembershipListListMetadata`
  - **[pipes](https://workos.com/docs/reference/pipes)**:
    - Added model `DataIntegrationCredentials`
    - Added model `DataIntegrationConfigurationResponse`
    - Added model `DataIntegrationConfigurationListResponse`
    - Added model `ConfigureDataIntegrationBody`
    - Added `auth_methods` to `DataIntegrationsListResponseData`
    - Added `auth_method` to `DataIntegrationsListResponseDataConnectedAccount`
    - Added `api_key_last_4` to `DataIntegrationsListResponseDataConnectedAccount`
    - Added enum `DataIntegrationCredentialsCredentialsType`
    - Added enum `DataIntegrationsListResponseDataAuthMethods`
    - Added enum `DataIntegrationsListResponseDataConnectedAccountAuthMethod`
    - Added service `PipesProvider`
  - **[user_management](https://workos.com/docs/reference/authkit/user)**:
    - Added model `UserInviteList`
    - Added model `UserInviteListListMetadata`
    - Made `AuthorizationCodeSessionAuthenticateRequest.client_secret` optional
    - Made `RefreshTokenSessionAuthenticateRequest.client_secret` optional
  - **[widgets](https://workos.com/docs/reference/widgets)**:
    - Added `widgets:pipes:manage` to `WidgetSessionTokenScopes`

  **Fixes**
  - **[organization_membership](https://workos.com/docs/reference/authkit/organization-membership)**:
    - Changed response of `UserManagementOrganizationMembership.list` from `UserOrganizationMembership` to `UserOrganizationMembershipList`
  - **[user_management](https://workos.com/docs/reference/authkit/user)**:
    - Changed response of `UserManagementInvitations.list` from `UserInvite` to `UserInviteList`

## [9.1.0](https://github.com/workos/workos-ruby/compare/v9.0.0...v9.1.0) (2026-06-17)

### Bug Fixes

* **renovate:** explicitly enable minor and patch updates ([#493](https://github.com/workos/workos-ruby/issues/493)) ([c6da3f3](https://github.com/workos/workos-ruby/commit/c6da3f3acdf4dd7a6a65b3ae6463102ff0c024e1))
* Use Thread.current[] instead of Fiber[] for connection cache ([#499](https://github.com/workos/workos-ruby/issues/499)) ([a44d650](https://github.com/workos/workos-ruby/commit/a44d6500b29d05fe7a5a0ac7449d1a4bee88fd38))

- [#495](https://github.com/workos/workos-ruby/pull/495) feat(generated): regenerate from spec (8 changes)

  **Features**
  - **[api_keys](https://workos.com/docs/reference/authkit/api-keys)**:
    - Added model `ExpireApiKey`
    - Added model `ApiKeyUpdated`
    - Added model `ApiKeyUpdatedData`
    - Added model `ApiKeyUpdatedDataOwner`
    - Added model `UserApiKeyUpdatedDataOwner`
    - Added model `ApiKeyUpdatedDataPreviousAttribute`
    - Added endpoint `POST /api_keys/{id}/expire`
  - **[audit_logs](https://workos.com/docs/reference/audit-logs)**:
    - Added `Snowflake` to `AuditLogConfigurationLogStreamType`
  - **[connect](https://workos.com/docs/reference/workos-connect/standalone)**:
    - Added `name` to `UserObject`
  - **[directory_sync](https://workos.com/docs/reference/directory-sync)**:
    - Added model `DsyncTokenCreated`
    - Added model `DsyncTokenCreatedData`
    - Added model `DsyncTokenRevoked`
    - Added model `DsyncTokenRevokedData`
  - **[user_management](https://workos.com/docs/reference/authkit/user)**:
    - Added `name` to user management models
  - **[webhooks](https://workos.com/docs/reference/webhooks)**:
    - Added `api_key.updated` to `CreateWebhookEndpointEvents`
    - Added `api_key.updated` to `UpdateWebhookEndpointEvents`

## [9.0.0](https://github.com/workos/workos-ruby/compare/v8.0.1...v9.0.0) (2026-05-26)

### Bug Fixes

* **ci:** extract version from PR title in changelog inline step ([93768a1](https://github.com/workos/workos-ruby/commit/93768a1c00aab7f82c869f38bea5925f6e8cd933))

* [#491](https://github.com/workos/workos-ruby/pull/491) feat(generated)!: regenerate from spec (9 changes)

  **⚠️ Breaking**
  * **organization_membership:** Migrate organization membership to dedicated service
    * Moved organization membership methods from `UserManagement` to new `OrganizationMembershipService` class
    * Methods `create_organization_membership`, `get_organization_membership`, `update_organization_membership`, `delete_organization_membership`, `deactivate_organization_membership`, `reactivate_organization_membership`, `list_organization_memberships`, and `list_organization_membership_groups` now accessed via `client.organization_membership` instead of `client.user_management`
    * Removed `UserManagement::RoleSingle` and `UserManagement::RoleMultiple` data classes (moved to `OrganizationMembershipService`)
  * **api_keys:** Add expires_at field to API key models
    * Added `expires_at` optional field to `ApiKey`, `OrganizationApiKey`, `OrganizationApiKeyWithValue`, `UserApiKey`, and `UserApiKeyWithValue` models
    * Added `expires_at` field to `CreateOrganizationApiKey` and `CreateUserApiKey` request models
    * Updated `create_organization_api_key` and `create_user_api_key` methods to accept `expires_at` parameter
  * **radar:** Remove device_fingerprint and bot_score fields from Radar
    * Removed `device_fingerprint` and `bot_score` parameters from `Radar.create_attempt` method
    * Removed `device_fingerprint` and `bot_score` fields from `RadarStandaloneAssessRequest` model
    * Updated enum values in `RadarStandaloneAssessRequestAction`: removed `LOGIN`, `SIGNUP`, `SIGN_UP_2`, `SIGN_IN_2`, `SIGN_IN_3`, `SIGN_UP_3`; standardized to `SIGN_UP` and `SIGN_IN`
    * Removed `CREDENTIAL_STUFFING` and `IP_SIGN_UP_RATE_LIMIT` from `RadarStandaloneResponseControl` enum
  * **audit_logs:** Refactor audit logs models and type names
    * Merged `AuditLogSchemaJson` fields into `AuditLogSchema`; removed `AuditLogSchemaJson` class
    * Added new `AuditLogSchemaInput` class (write-side schema without read-only fields)
    * Renamed `AuditLogSchemaJsonActor` to `AuditLogSchemaActorInput`
    * Renamed `AuditLogSchemaJsonTarget` to `AuditLogSchemaTargetInput`
    * Removed `AuditLogActionJson`; `AuditLogAction` now extends `BaseModel`
    * Renamed `AuditLogExportJson` to `AuditLogExport` (now extends `BaseModel`)
    * Renamed `AuditLogsRetentionJson` to `AuditLogsRetention` (now extends `BaseModel`)
    * Removed `AuditLogExportJsonState` type; replaced with `AuditLogExportState`
    * Updated `list_actions` method return type from `AuditLogActionJson` to `AuditLogAction`
    * Updated `create_export` and `get_export` method return types from `AuditLogExportJson` to `AuditLogExport`
  * **webhooks:** Rename WebhookEndpointJson to WebhookEndpoint
    * Renamed `WebhookEndpointJson` to `WebhookEndpoint`
    * Updated `list_webhook_endpoints`, `create_webhook_endpoint`, and `update_webhook_endpoint` method return types
    * `WebhookEndpointStatus` is now an alias for `UpdateWebhookEndpointStatus` (no longer a standalone class); removed `WebhookEndpointJsonStatus` alias
    * Updated `WebhookEndpoint` to extend `BaseModel` for consistency
  * **authorization:** Add filtering parameters to authorization list methods
    * Added `resource_id`, `resource_external_id`, `resource_type_slug` filter parameters to `list_role_assignments` method
    * Added `role_slug` filter parameter to `list_role_assignments_for_resource_by_external_id` and `list_role_assignments_for_resource` methods
    * Removed `search` parameter from `list_resources` method

  **Features**
  * **vault:** Add new Vault service with key-value operations
    * Added new `Vault` service class with methods: `create_data_key`, `create_decrypt`, `create_rekey`, `list_kv`, `create_kv`, `get_name`, `get_kv`, `update_kv`, `delete_kv`, `list_kv_metadata`, `list_kv_versions`
    * Added vault model classes: `Actor`, `CreateDataKeyRequest`, `CreateDataKeyResponse`, `CreateObjectRequest`, `DecryptRequest`, `DecryptResponse`, `DeleteObjectResponse`, `ObjectModel`, `ObjectMetadata`, `ObjectSummary`, `ObjectVersion`, `ObjectWithoutValue`, `RekeyRequest`, `UpdateObjectRequest`
    * Added `VaultOrder` enum for sorting operations
    * Added `client.vault` accessor to access the new service
  * **pipes:** Add Pipes connected account event models
    * Added `PipeConnectedAccount` model for representing connected accounts
    * Added three new event models: `PipesConnectedAccountConnected`, `PipesConnectedAccountDisconnected`, `PipesConnectedAccountReauthorizationNeeded`
    * Added `PipeConnectedAccountState` enum with `CONNECTED` and `NEEDS_REAUTHORIZATION` values
    * Added new webhook event types to `CreateWebhookEndpointEvents` and `UpdateWebhookEndpointEvents`
  * **generated:** Add Error and Actor shared models
    * Added `Error` model in shared module for error responses
    * Added `Actor` model in vault module representing user/actor information
    * Updated inflections to map 'object' to 'ObjectModel' to avoid conflicts

## [8.0.1](https://github.com/workos/workos-ruby/compare/v8.0.0...v8.0.1) (2026-05-12)


### Bug Fixes

* harden session sealing, log redaction, and webhook tolerance checks ([#482](https://github.com/workos/workos-ruby/issues/482)) ([347fe1e](https://github.com/workos/workos-ruby/commit/347fe1edf296778d7ea331e666a7957870074b9f))

## [8.0.0](https://github.com/workos/workos-ruby/compare/v7.1.2...v8.0.0) (2026-05-06)


### ⚠ BREAKING CHANGES

* **authorization:** Consolidate order enums to PaginationOrder
* **api_keys:** Separate organization and user API key types
* **user_management:** Consolidate order enums to PaginationOrder
* **vault:** Add BYOK key deleted event and consolidate key provider enum
* **types:** Consolidate pagination order enums
* **authorization:** Rename RoleAssignment to UserRoleAssignment

### Features

* **api_keys:** Separate organization and user API key types ([956386a](https://github.com/workos/workos-ruby/commit/956386a27cb0f8a8707442fa98b74a317f3f9920))
* **authorization:** Add new role assignment listing endpoints ([956386a](https://github.com/workos/workos-ruby/commit/956386a27cb0f8a8707442fa98b74a317f3f9920))
* **authorization:** Consolidate order enums to PaginationOrder ([956386a](https://github.com/workos/workos-ruby/commit/956386a27cb0f8a8707442fa98b74a317f3f9920))
* **authorization:** Rename RoleAssignment to UserRoleAssignment ([956386a](https://github.com/workos/workos-ruby/commit/956386a27cb0f8a8707442fa98b74a317f3f9920))
* **directory_sync:** Add name field to directory users ([956386a](https://github.com/workos/workos-ruby/commit/956386a27cb0f8a8707442fa98b74a317f3f9920))
* **docs:** publish YARD API docs + llms.txt to GitHub Pages ([#480](https://github.com/workos/workos-ruby/issues/480)) ([117eeac](https://github.com/workos/workos-ruby/commit/117eeac5d25c896c7a9b989592f3525f51e52a3d))
* **events:** Add admin_portal source to event context actor ([956386a](https://github.com/workos/workos-ruby/commit/956386a27cb0f8a8707442fa98b74a317f3f9920))
* **sso:** Add name field to SSO profile ([956386a](https://github.com/workos/workos-ruby/commit/956386a27cb0f8a8707442fa98b74a317f3f9920))
* **types:** Consolidate pagination order enums ([956386a](https://github.com/workos/workos-ruby/commit/956386a27cb0f8a8707442fa98b74a317f3f9920))
* **user_management:** Add get JWT template endpoint ([956386a](https://github.com/workos/workos-ruby/commit/956386a27cb0f8a8707442fa98b74a317f3f9920))
* **user_management:** Add user API key management ([956386a](https://github.com/workos/workos-ruby/commit/956386a27cb0f8a8707442fa98b74a317f3f9920))
* **user_management:** Add user field to membership and organization membership ([956386a](https://github.com/workos/workos-ruby/commit/956386a27cb0f8a8707442fa98b74a317f3f9920))
* **user_management:** Consolidate order enums to PaginationOrder ([956386a](https://github.com/workos/workos-ruby/commit/956386a27cb0f8a8707442fa98b74a317f3f9920))
* **vault:** Add BYOK key deleted event and consolidate key provider enum ([956386a](https://github.com/workos/workos-ruby/commit/956386a27cb0f8a8707442fa98b74a317f3f9920))

## [7.1.2](https://github.com/workos/workos-ruby/compare/v7.1.1...v7.1.2) (2026-05-06)


### Bug Fixes

* decode legacy v6 sealed sessions on unseal ([#479](https://github.com/workos/workos-ruby/issues/479)) ([1d8b4aa](https://github.com/workos/workos-ruby/commit/1d8b4aaa26e77e6d7820feb7e2f81278a77b0cf4))
* replace parameter-group hashes with typed variant classes ([#473](https://github.com/workos/workos-ruby/issues/473)) ([a66c15b](https://github.com/workos/workos-ruby/commit/a66c15b6070ad8c26f0ca0b9ad7414f7b2ce8d8a))
* set canonical User-Agent header format ([#476](https://github.com/workos/workos-ruby/issues/476)) ([6728358](https://github.com/workos/workos-ruby/commit/67283581886a122f36d907229a71211665623219))

## [7.1.1](https://github.com/workos/workos-ruby/compare/v7.1.0...v7.1.1) (2026-04-29)


### Bug Fixes

* seal session client-side in Session#refresh ([#470](https://github.com/workos/workos-ruby/issues/470)) ([32662ab](https://github.com/workos/workos-ruby/commit/32662ab3d67ffdcc895141aa8fd5efb22ba79fdb))

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
