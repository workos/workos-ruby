module WorkOS
  module UserManagement
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