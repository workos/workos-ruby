module WorkOS
  module Cache
    class Entry
      attr_reader :value, :expires_at

      def initialize(value, expires_in)
        @value = value
        @expires_at = expires_in ? Time.now + expires_in : nil
      end

      def expired?
        return false if expires_at.nil?

        Time.now > @expires_at
      end
    end

    class << self
      def fetch(key, expires_in: nil, force: false, &block)
        entry = store[key]

        if force || entry.nil? || entry.expired?
          value = block.call
          store[key] = Entry.new(value, expires_in)
          return value
        end

        entry.value
      end

      def read(key)
        entry = store[key]
        return nil if entry.nil? || entry.expired?

        entry.value
      end

      def write(key, value, expires_in: nil)
        store[key] = Entry.new(value, expires_in)
        value
      end

      def delete(key)
        store.delete(key)
      end

      def clear
        store.clear
      end

      def exist?(key)
        entry = store[key]
        !(entry.nil? || entry.expired?)
      end

      private

      def store
        @store ||= {}
      end
    end
  end
end
