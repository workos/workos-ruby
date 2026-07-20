# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained runtime

module WorkOS
  # Sentinel value representing an explicit JSON `null` in a request body.
  #
  # Optional SDK parameters default to `nil`, and any parameter left as `nil`
  # is omitted from the request entirely so the corresponding field is left
  # unchanged. That makes it impossible to clear a nullable field by passing
  # `nil`. Pass {WorkOS::Null} instead to send an explicit `null` and clear
  # the field.
  #
  # @example Clear an organization's external ID
  #   WorkOS.client.organizations.update_organization(
  #     id: org.id,
  #     external_id: WorkOS::Null,
  #   )
  #
  # @example Clear a user's external ID
  #   WorkOS.client.user_management.update_user(
  #     id: user.id,
  #     external_id: WorkOS::Null,
  #   )
  Null = Object.new

  def Null.to_json(*)
    "null"
  end

  def Null.as_json(*)
    nil
  end

  def Null.inspect
    "WorkOS::Null"
  end

  Null.freeze
end
