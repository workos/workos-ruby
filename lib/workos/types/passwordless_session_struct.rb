# frozen_string_literal: true
# typed: strict

require 'date'

module WorkOS
  module Types
    # This PasswordlessSessionStruct acts as a typed interface
    # for the Passwordless class
    class PasswordlessSessionStruct < T::Struct
      const :id, String
      const :email, String
      const :expires_at, Date
      const :link, String
    end
  end
end
