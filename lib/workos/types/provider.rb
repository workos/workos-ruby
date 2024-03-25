# frozen_string_literal: true

module WorkOS
  module Types
    # The Provider constants are declarations of a
    # fixed set of values for SSO Providers.
    module Provider
      GitHub = 'GitHubOAuth'
      Google = 'GoogleOAuth'
      Microsoft = 'MicrosoftOAuth'

      ALL = [GitHub, Google, Microsoft].freeze
    end
  end
end
