# frozen_string_literal: true
# typed: true

module WorkOS
  # The AuthenticationResponse class represents an Authentication Response as well as an corresponding
  # response data that can later be appended on.
  class RefreshAuthenticationResponse
    include HashProvider
    extend T::Sig

    attr_accessor :access_token, :refresh_token

    sig { params(authentication_response_json: String).void }
    def initialize(authentication_response_json)
      json = JSON.parse(authentication_response_json, symbolize_names: true)
      @access_token = T.let(json[:access_token], String)
      @refresh_token = T.let(json[:refresh_token], String)
    end

    def to_json(*)
      {
        access_token: access_token,
        refresh_token: refresh_token,
      }
    end
  end
end
