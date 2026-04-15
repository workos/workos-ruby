# @oagen-ignore-file — hand-maintained runtime
module WorkOS
  # Simple holder for configuration parameters.
  class Configuration
    attr_accessor :api_key, :base_url, :client_id, :timeout, :max_retries

    def initialize
      @base_url = WorkOS::BaseClient::DEFAULT_BASE_URL
      @timeout = WorkOS::BaseClient::DEFAULT_TIMEOUT
      @max_retries = WorkOS::BaseClient::DEFAULT_MAX_RETRIES
    end
  end
end
