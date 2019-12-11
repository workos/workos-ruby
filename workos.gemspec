# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'workos/version'

Gem::Specification.new do |spec|
  spec.name          = 'workos'
  spec.version       = WorkOS::VERSION
  spec.authors       = ['WorkOS', 'Sam Bauch', 'Mark Tran']
  spec.email         = ['team@workos.com', 'sam@workos.com', 'mark@workos.com']
  spec.description   = 'API client for WorkOS'
  spec.summary       = 'API client for WorkOS'
  spec.homepage      = 'https://github.com/workos/workos-ruby'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'rack', '~> 1.6.4'
  spec.add_dependency 'sorbet-runtime'

  spec.add_development_dependency 'bundler', '~> 2.0.1'
  spec.add_development_dependency 'codecov', '~> 0.1.16'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.9.0'
  spec.add_development_dependency 'rubocop', '~> 0.77'
  spec.add_development_dependency 'sorbet'
  spec.add_development_dependency 'webmock'
end
