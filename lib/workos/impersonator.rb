# frozen_string_literal: true

module WorkOS
  # Contains information about a WorkOS Dashboard user impersonating
  # a User Management user.
  class Impersonator
    include HashProvider

    attr_accessor :email, :reason

    def initialize(email:, reason:)
      @email = email
      @reason = reason
    end

    def to_json(*)
      {
        email: email,
        reason: reason,
      }
    end
  end
end
