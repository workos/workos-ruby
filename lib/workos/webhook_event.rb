# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained runtime
require "json"

module WorkOS
  # Typed wrapper around a parsed webhook event payload.
  #
  #   event = client.webhooks.construct_event(
  #     payload: body, sig_header: sig, secret: ENV["WORKOS_WEBHOOK_SECRET"]
  #   )
  #   event.event      # => "connection.activated"
  #   event.id         # => "evt_01..."
  #   event.data       # => WorkOS::ConnectionActivatedData (typed) or Hash (unknown event)
  #   event.created_at # => "2026-04-16T..."
  #   event.raw        # => original Hash for escape hatch
  class WebhookEvent
    attr_reader :id, :event, :data, :created_at, :raw

    # Map of event type string -> data model class name.
    # Entries with nil mean "no typed model yet" and will return the raw hash.
    EVENT_DATA_MODELS = {
      "authentication.email_verification_succeeded" => "WorkOS::AuthenticationEmailVerificationSucceededData",
      "authentication.magic_auth_failed" => "WorkOS::AuthenticationMagicAuthFailedData",
      "authentication.magic_auth_succeeded" => "WorkOS::AuthenticationMagicAuthSucceededData",
      "authentication.mfa_succeeded" => "WorkOS::AuthenticationMFASucceededData",
      "authentication.oauth_failed" => "WorkOS::AuthenticationOAuthFailedData",
      "authentication.oauth_succeeded" => "WorkOS::AuthenticationOAuthSucceededData",
      "authentication.password_failed" => "WorkOS::AuthenticationPasswordFailedData",
      "authentication.password_succeeded" => "WorkOS::AuthenticationPasswordSucceededData",
      "authentication.passkey_failed" => "WorkOS::AuthenticationPasskeyFailedData",
      "authentication.passkey_succeeded" => "WorkOS::AuthenticationPasskeySucceededData",
      "authentication.sso_failed" => "WorkOS::AuthenticationSSOFailedData",
      "authentication.sso_started" => "WorkOS::AuthenticationSSOStartedData",
      "authentication.sso_succeeded" => "WorkOS::AuthenticationSSOSucceededData",
      "authentication.sso_timed_out" => "WorkOS::AuthenticationSSOTimedOutData",
      "authentication.radar_risk_detected" => "WorkOS::AuthenticationRadarRiskDetectedData",
      "api_key.created" => "WorkOS::ApiKeyCreatedData",
      "api_key.revoked" => "WorkOS::ApiKeyRevokedData",
      "connection.activated" => "WorkOS::ConnectionActivatedData",
      "connection.deactivated" => "WorkOS::ConnectionDeactivatedData",
      "connection.deleted" => "WorkOS::ConnectionDeletedData",
      "connection.saml_certificate_renewal_required" => "WorkOS::ConnectionSAMLCertificateRenewalRequiredData",
      "connection.saml_certificate_renewed" => "WorkOS::ConnectionSAMLCertificateRenewedData",
      "dsync.activated" => "WorkOS::DsyncActivatedData",
      "dsync.deleted" => "WorkOS::DsyncDeletedData",
      "dsync.group.created" => nil,
      "dsync.group.deleted" => nil,
      "dsync.group.updated" => "WorkOS::DsyncGroupUpdatedData",
      "dsync.group.user_added" => "WorkOS::DsyncGroupUserAddedData",
      "dsync.group.user_removed" => "WorkOS::DsyncGroupUserRemovedData",
      "dsync.user.created" => nil,
      "dsync.user.deleted" => nil,
      "dsync.user.updated" => "WorkOS::DsyncUserUpdatedData",
      "email_verification.created" => "WorkOS::EmailVerificationCreatedData",
      "group.created" => nil,
      "group.deleted" => nil,
      "group.updated" => nil,
      "group.member_added" => "WorkOS::GroupMemberAddedData",
      "group.member_removed" => "WorkOS::GroupMemberRemovedData",
      "flag.created" => "WorkOS::FlagCreatedData",
      "flag.deleted" => "WorkOS::FlagDeletedData",
      "flag.updated" => "WorkOS::FlagUpdatedData",
      "flag.rule_updated" => "WorkOS::FlagRuleUpdatedData",
      "invitation.accepted" => "WorkOS::InvitationAcceptedData",
      "invitation.created" => "WorkOS::InvitationCreatedData",
      "invitation.resent" => "WorkOS::InvitationResentData",
      "invitation.revoked" => "WorkOS::InvitationRevokedData",
      "magic_auth.created" => "WorkOS::MagicAuthCreatedData",
      "organization.created" => "WorkOS::OrganizationCreatedData",
      "organization.deleted" => "WorkOS::OrganizationDeletedData",
      "organization.updated" => "WorkOS::OrganizationUpdatedData",
      "organization_domain.created" => "WorkOS::OrganizationDomainCreatedData",
      "organization_domain.deleted" => "WorkOS::OrganizationDomainDeletedData",
      "organization_domain.updated" => "WorkOS::OrganizationDomainUpdatedData",
      "organization_domain.verified" => "WorkOS::OrganizationDomainVerifiedData",
      "organization_domain.verification_failed" => "WorkOS::OrganizationDomainVerificationFailedData",
      "password_reset.created" => "WorkOS::PasswordResetCreatedData",
      "password_reset.succeeded" => "WorkOS::PasswordResetSucceededData",
      "user.created" => nil,
      "user.updated" => nil,
      "user.deleted" => nil,
      "organization_membership.created" => "WorkOS::OrganizationMembershipCreatedData",
      "organization_membership.deleted" => "WorkOS::OrganizationMembershipDeletedData",
      "organization_membership.updated" => "WorkOS::OrganizationMembershipUpdatedData",
      "role.created" => "WorkOS::RoleCreatedData",
      "role.deleted" => "WorkOS::RoleDeletedData",
      "role.updated" => "WorkOS::RoleUpdatedData",
      "organization_role.created" => "WorkOS::OrganizationRoleCreatedData",
      "organization_role.deleted" => "WorkOS::OrganizationRoleDeletedData",
      "organization_role.updated" => "WorkOS::OrganizationRoleUpdatedData",
      "permission.created" => "WorkOS::PermissionCreatedData",
      "permission.deleted" => "WorkOS::PermissionDeletedData",
      "permission.updated" => "WorkOS::PermissionUpdatedData",
      "session.created" => "WorkOS::SessionCreatedData",
      "session.revoked" => "WorkOS::SessionRevokedData"
    }.freeze

    def initialize(raw_hash)
      @raw = raw_hash
      @id = raw_hash["id"]
      @event = raw_hash["event"]
      @created_at = raw_hash["created_at"]
      @data = coerce_data(raw_hash["data"])
    end

    private

    def coerce_data(data_hash)
      return data_hash unless data_hash.is_a?(Hash) && @event
      model_name = EVENT_DATA_MODELS[@event]
      return data_hash unless model_name

      klass = Object.const_get(model_name)
      klass.new(data_hash)
    rescue NameError, JSON::ParserError
      data_hash
    end
  end
end
