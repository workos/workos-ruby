# frozen_string_literal: true

module WorkOS
  # The Cache module provides a simple in-memory cache for storing values
  # This module is not meant to be instantiated in a user space, and is used internally by the SDK
  module Cache
    # The Entry class represents a cache entry with a value and an expiration time
    class Entry
      attr_reader :value, :expires_at

      def initialize(value, expires_in)
        @value = value
        @expires_at = expires_in ? Time.now + expires_in : nil
      end

      # Checks if the entry has expired
      # @return [Boolean] True if the entry has expired, false otherwise
      def expired?
        return false if expires_at.nil?

        Time.now > @expires_at
      end
    end

    class << self
      # Fetches a value from the cache, or calls the block to fetch the value if it is not present
      # @param key [String] The key to fetch the value for
      # @param expires_in [Integer] The expiration time for the value in seconds
      # @param force [Boolean] If true, the value will be fetched from the block even if it is present in the cache
      # @param block [Proc] The block to call to fetch the value if it is not present in the cache
      # @return [Object] The value fetched from the cache or the block
      def fetch(key, expires_in: nil, force: false, &block)
        entry = store[key]

        if force || entry.nil? || entry.expired?
          value = block.call
          store[key] = Entry.new(value, expires_in)
          return value
        end

        entry.value
      end

      # Reads a value from the cache
      # @param key [String] The key to read the value for
      # @return [Object] The value read from the cache, or nil if the value is not present or has expired
      def read(key)
        entry = store[key]
        return nil if entry.nil? || entry.expired?

        entry.value
      end

      # Writes a value to the cache
      # @param key [String] The key to write the value for
      # @param value [Object] The value to write to the cache
      # @param expires_in [Integer] The expiration time for the value in seconds
      # @return [Object] The value written to the cache
      def write(key, value, expires_in: nil)
        store[key] = Entry.new(value, expires_in)
        value
      end

      # Deletes a value from the cache
      # @param key [String] The key to delete the value for
      def delete(key)
        store.delete(key)
      end

      # Clears all values from the cache
      def clear
        store.clear
      end

      # Checks if a value exists in the cache
      # @param key [String] The key to check for
      # @return [Boolean] True if the value exists and has not expired, false otherwise
      def exist?(key)
        entry = store[key]
        !(entry.nil? || entry.expired?)
      end

      private

      # The in-memory store for the cache
      def store
        @store ||= {}
      end
    end
  end
end
