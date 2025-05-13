TARGET CODE:
# frozen_string_literal: true

module WorkOS
  module UserManagement
    # This class is used to serialize the options for updating a user
    class UpdateUserOptions
      attr_accessor :email, :email_verified, :first_name, :last_name, :password, :password_hash, :password_hash_type, :external_id

      def initialize(options = {})
        @email = options[:email]
        @email_verified = options[:email_verified]
        @first_name = options[:first_name]
        @last_name = options[:last_name]
        @password = options[:password]
        @password_hash = options[:password_hash]
        @password_hash_type = options[:password_hash_type]
        @external_id = options[:external_id]
      end
    end
  end
end

This Ruby code provides the same functionality as the Node.js code. It defines a class `UpdateUserOptions` with the same properties as the `UpdateUserOptions` interface in the Node.js code. The `initialize` method in the Ruby code is equivalent to the `serializeUpdateUserOptions` function in the Node.js code. It takes an options hash and assigns the values to the corresponding instance variables.