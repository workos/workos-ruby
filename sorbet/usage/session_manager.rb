# frozen_string_literal: true
# typed: strict

# @oagen-ignore-file
#
# Type-checked by `srb tc`, never run. A strictly typed caller of the
# hand-maintained signatures in rbi/workos/session_manager.rbi; see
# sorbet/usage/workload_identity.rb for why these files exist.

auth_error = WorkOS::SessionManager::AuthError.new(
  authenticated: false,
  reason: WorkOS::SessionManager::EXPIRED_JWT
)
T.assert_type!(auth_error.authenticated, T::Boolean)
T.assert_type!(auth_error.reason, T.nilable(String))

refresh_error = WorkOS::SessionManager::RefreshError.new(
  authenticated: false,
  reason: "invalid_grant",
  sealed_session: "sealed-cookie"
)
T.assert_type!(refresh_error.reason, T.nilable(String))
T.assert_type!(refresh_error.sealed_session, T.nilable(String))

refresh_success = WorkOS::SessionManager::RefreshSuccess.new(
  authenticated: true,
  sealed_session: "sealed-cookie",
  session_id: "session_123",
  organization_id: "org_123",
  role: "member",
  roles: ["member"],
  permissions: ["widgets:read"],
  entitlements: []
)
T.assert_type!(refresh_success.authenticated, T::Boolean)
T.assert_type!(refresh_success.sealed_session, T.nilable(String))
T.assert_type!(refresh_success.roles, T.nilable(T::Array[String]))
refresh_success.role = "admin"

# Every member of a keyword_init Struct is optional.
WorkOS::SessionManager::RefreshSuccess.new(authenticated: true)
