# typed: true
# frozen_string_literal: true

require 'workos/version'
require 'sorbet-runtime'
# :nodoc:
module WorkOS
  API_HOSTNAME = 'api.workos.com'

  def self.key=(value)
    Base.key = value
  end

  def self.key
    Base.key
  end

  def self.key!
    key || raise('WorkOS.key not set')
  end

  autoload :Base, 'workos/base'
  autoload :SSO, 'workos/sso'

  WorkOS.key = ENV['WORKOS_KEY'] unless ENV['WORKOS_KEY'].nil?
end
