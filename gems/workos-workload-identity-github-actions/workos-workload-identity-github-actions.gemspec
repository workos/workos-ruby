# frozen_string_literal: true

require_relative "lib/workos/workload_identity/github_actions/version"

Gem::Specification.new do |spec|
  spec.name = "workos-workload-identity-github-actions"
  spec.version = WorkOS::WorkloadIdentity::GitHubActions::VERSION
  spec.authors = ["WorkOS"]
  spec.email = ["support@workos.com"]
  spec.summary = "GitHub Actions identity token provider for WorkOS workload identity federation"
  spec.description = "Fetches a GitHub Actions OIDC token for the WorkOS SDK to exchange, " \
    "so a workflow can call the WorkOS API without a stored API key."
  spec.homepage = "https://github.com/workos/workos-ruby"
  spec.license = "MIT"
  spec.metadata = {
    "documentation_uri" => "https://docs.workos.com/sdk/ruby",
    "source_code_uri" => "https://github.com/workos/workos-ruby/tree/main/gems/workos-workload-identity-github-actions",
    "changelog_uri" => "https://github.com/workos/workos-ruby/blob/main/gems/workos-workload-identity-github-actions/CHANGELOG.md"
  }

  spec.files = Dir.chdir(__dir__) { Dir["lib/**/*.rb", "CHANGELOG.md", "LICENSE", "README.md"] }
  spec.require_paths = ["lib"]

  # No runtime dependencies. In particular this gem does not depend on the
  # WorkOS SDK gem: a provider is anything that responds to `call`.
  spec.add_development_dependency "minitest", "~> 6.0"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "standard", "~> 1.49"

  spec.required_ruby_version = ">= 3.3"
end
