# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'workos/version'

Gem::Specification.new do |spec|
  spec.name = 'workos'
  spec.version = WorkOS::VERSION
  spec.authors = ['WorkOS']
  spec.email = ['support@workos.com']
  spec.description = 'API client for WorkOS'
  spec.summary = 'API client for WorkOS'
  spec.homepage = 'https://github.com/workos-inc/workos-ruby'
  spec.license = 'MIT'
  spec.metadata = {
    'documentation_uri' => 'https://docs.workos.com/sdk/ruby',
  }

  spec.files = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'encryptor', '~> 3.0'
  spec.add_dependency 'jwt', '~> 2.8'

  spec.add_development_dependency 'bundler', '>= 2.0.1'
  spec.add_development_dependency 'rspec', '~> 3.9.0'
  spec.add_development_dependency 'rubocop', '~> 1.71'
  spec.add_development_dependency 'vcr', '~> 6.0'
  spec.add_development_dependency 'webmock'

  spec.required_ruby_version = '>= 3.1'
end
