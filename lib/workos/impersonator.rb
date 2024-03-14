# frozen_string_literal: true
# typed: true

module WorkOS
  class Impersonator
    include HashProvider
    extend T::Sig

    attr_accessor :email, :reason

    sig { params(email: String, reason: T.nilable(String)).void }
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
