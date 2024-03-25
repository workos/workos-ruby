# frozen_string_literal: true

module WorkOS
  module Types
    class PasswordlessSessionStruct
      attr_accessor :id, :email, :expires_at, :link

      def initialize(id:, email:, expires_at:, link:)
        @id = id
        @email = email
        @expires_at = expires_at
        @link = link
      end
    end
  end
end
