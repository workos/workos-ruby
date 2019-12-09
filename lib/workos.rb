# frozen_string_literal: true

require 'workos/version'

module WorkOS
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
  autoload :Constants, 'workos/constants'
  autoload :SSO, 'workos/sso'

  WorkOS.key = ENV['WORKOS_KEY'] unless ENV['WORKOS_KEY'].nil?
end
