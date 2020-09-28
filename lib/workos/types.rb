# frozen_string_literal: true

require 'require_all'

module WorkOS
  # WorkOS believes strongly in typed languages,
  # so we're using Sorbet throughout this Ruby gem.
  module Types
    require_all 'lib/workos/types'
  end
end
