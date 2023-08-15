# frozen_string_literal: true
# typed: true

require 'net/http'
require 'uri'

module WorkOS
  # The UserManagement module provides convenience methods for working with the
  # WorkOS User platform. You'll need a valid API key.
  module UserManagement
    class << self
      extend T::Sig
      include Client

      sig do
        params(id: String).returns(WorkOS::User)
      end
      def get_user(id:)
        response = execute_request(
          request: get_request(
            path: "/users/#{id}",
            auth: true,
          ),
        )

        WorkOS::User.new(response.body)
      end
    end
  end
end
