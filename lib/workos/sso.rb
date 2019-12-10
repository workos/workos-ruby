# typed: true
# frozen_string_literal: true

require 'rack/utils'
require 'workos/constants'

module WorkOS
  # :nodoc:
  class SSO
    extend T::Sig

    sig do
      params(
        domain: String,
        project_id: String,
        redirect_uri: String,
        state: Hash,
      ).returns(String)
    end

    def self.get_authorization_url(domain:, project_id:, redirect_uri:, state:)
      query = Rack::Utils.build_query(
        domain: domain,
        client_id: project_id,
        redirect_uri: redirect_uri,
        response_type: 'code',
        state: state
      )

      "https://#{WorkOS::API_HOSTNAME}/sso/authorize?#{query}"
    end

    def self.get_profile(code:, project_id:, redirect_uri:); end
  end
end
