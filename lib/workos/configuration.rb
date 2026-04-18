# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained runtime
module WorkOS
  # Simple holder for configuration parameters.
  class Configuration
    attr_accessor :api_key, :base_url, :client_id, :timeout, :max_retries, :logger, :log_level

    def initialize
      @base_url = WorkOS::BaseClient::DEFAULT_BASE_URL
      @timeout = WorkOS::BaseClient::DEFAULT_TIMEOUT
      @max_retries = WorkOS::BaseClient::DEFAULT_MAX_RETRIES
    end
  end

  class << self
    # Yield the global configuration for modification.
    #
    #   WorkOS.configure do |config|
    #     config.api_key = "sk_..."
    #     config.client_id = "client_..."
    #   end
    def configure
      yield(configuration)
    end

    # The global configuration instance.
    def configuration
      @configuration ||= Configuration.new
    end

    # A convenience client built from the global configuration.
    # Lazy-initialized; reset by calling WorkOS.reset_client.
    def client
      @client ||= Client.new(
        api_key: configuration.api_key,
        base_url: configuration.base_url,
        client_id: configuration.client_id,
        timeout: configuration.timeout,
        max_retries: configuration.max_retries,
        logger: configuration.logger,
        log_level: configuration.log_level
      )
    end

    # Reset the cached client (e.g., after reconfiguring).
    def reset_client
      @client&.shutdown
      @client = nil
    end
  end
end
