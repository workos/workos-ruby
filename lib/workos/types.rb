# frozen_string_literal: true
# typed: strict

module WorkOS
  # WorkOS believes strongly in typed languages,
  # so we're using Sorbet throughout this Ruby gem.
  module Types
    require_relative 'types/connection_struct'
    require_relative 'types/profile_struct'
    require_relative 'types/provider_enum'
  end
end
