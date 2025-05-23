# frozen_string_literal: true

require 'net/http'
require 'uri'

module WorkOS
  # The MFA module provides convenience methods for working with the WorkOS
  # MFA platform. You'll need a valid API key
  module MFA
    class << self
      include Client, Deprecation

      def delete_factor(id:)
        response = execute_request(
          request: delete_request(
            path: "/auth/factors/#{id}",
            auth: true,
          ),
        )
        response.is_a? Net::HTTPSuccess
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

      # rubocop:disable Metrics/PerceivedComplexity
      def validate_args(
        type:,
        totp_issuer: nil,
        totp_user: nil,
        phone_number: nil
      )
        if type != 'sms' && type != 'totp' && type != 'generic_otp'
          raise ArgumentError, "Type argument must be either 'sms' or 'totp'"
        end
        if (type == 'totp' && totp_issuer.nil?) || (type == 'totp' && totp_user.nil?)
          raise ArgumentError, 'Incomplete arguments. Need to specify both totp_issuer and totp_user when type is totp'
        end
        return unless type == 'sms' && phone_number.nil?

        raise ArgumentError, 'Incomplete arguments. Need to specify phone_number when type is sms'
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      def enroll_factor(
        type:,
        totp_issuer: nil,
        totp_user: nil,
        phone_number: nil
      )
        validate_args(
          type: type,
          totp_issuer: totp_issuer,
          totp_user: totp_user,
          phone_number: phone_number,
        )
        response = execute_request(request: post_request(
          auth: true,
          body: {
            type: type,
            totp_issuer: totp_issuer,
            totp_user: totp_user,
            phone_number: phone_number,
          },
          path: '/auth/factors/enroll',
        ))
        WorkOS::Factor.new(response.body)
      end

      def challenge_factor(
        authentication_factor_id: nil,
        sms_template: nil
      )
        if authentication_factor_id.nil?
          raise ArgumentError, "Incomplete arguments: 'authentication_factor_id' is a required argument"
        end

        request = post_request(
          auth: true,
          body: {
            sms_template: sms_template,
          },
          path: "/auth/factors/#{authentication_factor_id}/challenge",
        )

        response = execute_request(request: request)
        WorkOS::Challenge.new(response.body)
      end

      def verify_factor(
        authentication_challenge_id: nil,
        code: nil
      )
        warn_deprecation '`verify_factor` is deprecated. Please use `verify_challenge` instead.'

        verify_challenge(
          authentication_challenge_id: authentication_challenge_id,
          code: code,
        )
      end

      def verify_challenge(
        authentication_challenge_id: nil,
        code: nil
      )

        if authentication_challenge_id.nil? || code.nil?
          raise ArgumentError, "Incomplete arguments: 'authentication_challenge_id' and 'code' are required arguments"
        end

        options = {
          "code": code,
        }

        response = execute_request(
          request: post_request(
            path: "/auth/challenges/#{authentication_challenge_id}/verify",
            auth: true,
            body: options,
          ),
        )
        WorkOS::VerifyChallenge.new(response.body)
      end
    end
  end
end
