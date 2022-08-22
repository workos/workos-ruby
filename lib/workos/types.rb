# frozen_string_literal: true
# typed: strong

module WorkOS
  # WorkOS believes strongly in typed languages,
  # so we're using Sorbet throughout this Ruby gem.
  module Types
    require_relative 'types/audit_log_export_struct'
    require_relative 'types/connection_struct'
    require_relative 'types/directory_struct'
    require_relative 'types/directory_group_struct'
    require_relative 'types/intent_enum'
    require_relative 'types/list_struct'
    require_relative 'types/organization_struct'
    require_relative 'types/passwordless_session_struct'
    require_relative 'types/profile_struct'
    require_relative 'types/provider_enum'
    require_relative 'types/directory_user_struct'
    require_relative 'types/webhook_struct'
    require_relative 'types/factor_struct'
    require_relative 'types/challenge_struct'
    require_relative 'types/verify_challenge_struct'
  end
end
