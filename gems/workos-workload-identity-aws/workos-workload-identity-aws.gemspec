# frozen_string_literal: true

require_relative "lib/workos/workload_identity/aws/version"

Gem::Specification.new do |spec|
  spec.name = "workos-workload-identity-aws"
  spec.version = WorkOS::WorkloadIdentity::AWS::VERSION
  spec.authors = ["WorkOS"]
  spec.email = ["support@workos.com"]
  spec.summary = "AWS identity token provider for WorkOS workload identity federation"
  spec.description = "Fetches an AWS identity token from STS (GetWebIdentityToken) for the WorkOS SDK to exchange, " \
    "so a workload on AWS can call the WorkOS API without a stored API key."
  spec.homepage = "https://github.com/workos/workos-ruby"
  spec.license = "MIT"
  spec.metadata = {
    "documentation_uri" => "https://docs.workos.com/sdk/ruby",
    "source_code_uri" => "https://github.com/workos/workos-ruby/tree/main/gems/workos-workload-identity-aws",
    "changelog_uri" => "https://github.com/workos/workos-ruby/blob/main/gems/workos-workload-identity-aws/CHANGELOG.md"
  }

  spec.files = Dir.chdir(__dir__) { Dir["lib/**/*.rb", "CHANGELOG.md", "LICENSE", "README.md"] }
  spec.require_paths = ["lib"]

  # The AWS SDK lives here and only here; the WorkOS SDK gem never depends on
  # it, and this gem does not depend on the WorkOS SDK gem.
  #
  # `aws-sdk-sts` is AWS's alias gem for the STS client, which ships inside
  # `aws-sdk-core`. The alias accepts any core from 3.110, so the floor that
  # matters is stated as well: 3.238.0 is the first release with
  # GetWebIdentityToken.
  spec.add_dependency "aws-sdk-sts", "~> 1.12"
  spec.add_dependency "aws-sdk-core", ">= 3.238.0", "< 4"

  spec.add_development_dependency "minitest", "~> 6.0"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "standard", "~> 1.49"

  spec.required_ruby_version = ">= 3.3"
end
