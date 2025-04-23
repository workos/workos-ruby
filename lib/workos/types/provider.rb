# frozen_string_literal: true

module WorkOS
  module Types
    # The Provider constants are declarations of a
    # fixed set of values for SSO Providers.
    module Provider
      Apple = 'AppleOAuth'
      GitHub = 'GitHubOAuth'
      Google = 'GoogleOAuth'
      Microsoft = 'MicrosoftOAuth'

      ALL = [Apple, GitHub, Google, Microsoft].freeze
    end
  end
end
