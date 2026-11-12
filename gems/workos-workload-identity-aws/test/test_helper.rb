# frozen_string_literal: true

# @oagen-ignore-file
$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "minitest/autorun"
require "fileutils"
require "tmpdir"

# No test may reach AWS, and none may depend on the machine it runs on. All of
# this is set before the AWS SDK loads: static credentials, so the credential
# chain never asks the instance metadata service, and empty config files in
# place of ~/.aws, so no region or profile leaks in.
AWS_TEST_HOME = Dir.mktmpdir("workos-wif-aws")
Minitest.after_run { FileUtils.remove_entry(AWS_TEST_HOME) }
%w[config credentials].each { |name| File.write(File.join(AWS_TEST_HOME, name), "") }
ENV["AWS_CONFIG_FILE"] = File.join(AWS_TEST_HOME, "config")
ENV["AWS_SHARED_CREDENTIALS_FILE"] = File.join(AWS_TEST_HOME, "credentials")
ENV["AWS_EC2_METADATA_DISABLED"] = "true"
ENV["AWS_ACCESS_KEY_ID"] = "test-access-key-id"
ENV["AWS_SECRET_ACCESS_KEY"] = "test-secret-access-key"
%w[AWS_PROFILE AWS_SESSION_TOKEN AWS_REGION AWS_DEFAULT_REGION AMAZON_REGION AWS_STS_REGIONAL_ENDPOINTS].each { |name| ENV.delete(name) }

require "workos-workload-identity-aws"
