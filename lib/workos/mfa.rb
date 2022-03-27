# frozen_string_literal: true
# typed: true

require 'net/http'
require 'uri'

module WorkOS

  module MFA
    class << self
      extend T::Sig
      include Base
      include Client
      
      sig { params(id: String).returns(T::Boolean) }
      def delete_factor(id:)
        response = execute_request(
            request: delete_request(
              path: "/auth/factors/#{id}",
              auth: true,
            ),
        )
        response.is_a? Net::HTTPSuccess
      end

      sig do
        params(
          id: String,
        ).returns(WorkOS::Factor)
      end
      def get_factor(
          id:
        )
        response = execute_request(
            request: get_request(
              path: "/auth/factors/#{id}",
              auth: true,
            ),
        )
        WorkOS::Factor.new(response.body)
      end

      sig do
        params(
            type: String,
            totp_issuer: T.nilable(String),
            totp_user: T.nilable(String),
            phone_number: T.nilable(String),
        ).returns(WorkOS::Factor)
      end
      def enroll_factor(
          type:,
          totp_issuer: nil,
          totp_user: nil,
          phone_number: nil
        )

        if type != "sms" and type != "totp" and type != "generic_otp"
            raise ArgumentError, "Type parameter must be either 'sms' or 'totp'"
        end

        if (type == "totp" and totp_issuer == nil) or (type == "totp" and totp_user == nil)
            raise ArgumentError, "Incomplete arguments. Need to specify both totp_issuer and totp_user when type is totp"
        end

        if type == "sms" and phone_number == nil
            raise ArgumentError, "Incomplete arguments. Need to specify phone_number when type is sms"
            
        end
        # this condition is added as type is sms will return a 500 if content type is application/json
        if type == "totp" or type == "generic_otp"
            request = post_request( 
                auth: true,
                body: {
                    type: type,
                    totp_issuer: totp_issuer,
                    totp_user: totp_user,
                    phone_number: phone_number,
                    },
                path: '/auth/factors/enroll',
            )

            response = execute_request(request: request)
            WorkOS::Factor.new(response.body)

        elsif type == 'sms'
            url = URI("https://#{WorkOS::API_HOSTNAME}/auth/factors/enroll")

            https = Net::HTTP.new(url.host, url.port)
            https.use_ssl = true
            
            request = Net::HTTP::Post.new(url)
            request["Authorization"] = "Bearer #{WorkOS.key!}"
            request["Content-Type"] = "application/x-www-form-urlencoded"

            encoded_number = ERB::Util.url_encode(phone_number)
            request.body = "type=sms&phone_number=#{encoded_number}"
            response = https.request(request)
            WorkOS::Factor.new(response.body)
        end
      end

      sig do
        params(
          authentication_factor_id: String,
          sms_template: T.nilable(String),
        ).returns(WorkOS::ChallengeFactor)
      end
      def challenge_factor(
        authentication_factor_id:,
        sms_template: nil
    )

        if authentication_factor_id == nil
            raise ArgumentError, "Incomplete arguments: 'authentication_factor_id' is a required parameter"
        end

        request = post_request( 
            auth: true,
            body: {
                sms_template: sms_template,
                authentication_factor_id: authentication_factor_id,
                },
            path: '/auth/factors/challenge',
        )

        response = execute_request(request: request)
        WorkOS::ChallengeFactor.new(response.body)
      end

      sig do
        params(
          authentication_challenge_id: String,
          code: String,
        ).returns(WorkOS::VerifyFactor)
      end
      def verify_factor(
        authentication_challenge_id:,
        code:
        )

        if authentication_challenge_id == nil or code == nil
            raise ArgumentError, "Incomplete arguments: 'authentication_challenge_id' and 'code' are required parameters"
        end

        options = {
            "authentication_challenge_id": authentication_challenge_id,
            "code": code,
        }

        response = execute_request(
            request: post_request(
            path: '/auth/factors/verify',
            auth: true,
            body: options
            ),
        )
        WorkOS::VerifyFactor.new(response.body)
       end
    end
  end
end