# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained runtime
module WorkOS
  # The credentials behind a client built with `api_key:`. The key never
  # changes, so there is nothing to refresh and a 401 is not recoverable.
  class StaticKeyCredentials
    def initialize(api_key)
      headers = (api_key.nil? || api_key.empty?) ? {} : {"Authorization" => "Bearer #{api_key}"}
      @snapshot = CredentialSnapshot.new(headers: headers.freeze, generation: 0, recoverable: false)
    end

    def resolve(timeout: nil)
      @snapshot
    end

    def invalidate(_generation)
      nil
    end

    def inspect
      "#<#{self.class.name}>"
    end
  end
end
