# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained runtime
module WorkOS
  module Types
    # Paginated response wrapper with auto-pagination support.
    #
    #   result = @client.organizations.list_organizations(limit: 10)
    #   result.data              # => [WorkOS::Organization, ...]
    #   result.list_metadata     # => { "before" => nil, "after" => "org_..." }
    #   result.auto_paging_each { |org| puts org.id }
    class ListStruct
      include Enumerable

      attr_accessor :data, :list_metadata, :fetch_next, :fetch_previous, :filters

      def initialize(data:, list_metadata:, fetch_next: nil, fetch_previous: nil, filters: {})
        @data = data || []
        @list_metadata = list_metadata || {}
        @fetch_next = fetch_next
        @fetch_previous = fetch_previous
        @filters = filters
      end

      # Build a ListStruct from a raw HTTP response, mapping items through
      # an optional model class and wiring cursor-based auto-pagination.
      #
      # @param response [Net::HTTPResponse] Raw HTTP response with JSON body.
      # @param model [Class, nil] Model class whose `.new` accepts a Hash.
      #   When nil, items are returned as raw Hashes.
      # @param filters [Hash] Filter state forwarded to the next page.
      # @param fetch_next [Proc, nil] Proc called to fetch the next page given
      #   the current page's `after` cursor.
      # @param fetch_previous [Proc, nil] Proc called to fetch the previous page
      #   given the current page's `before` cursor.
      # @return [ListStruct]
      def self.from_response(response, model: nil, filters: {}, fetch_next: nil, fetch_previous: nil)
        parsed = JSON.parse(response.body)
        items = parsed["data"] || []
        items = items.map { |item| model.new(item) } if model
        new(
          data: items,
          list_metadata: parsed["list_metadata"],
          filters: filters,
          fetch_next: fetch_next,
          fetch_previous: fetch_previous
        )
      end

      # Iterates the current page only. Use `auto_paging_each` to span pages.
      #
      # @return [Enumerator]
      def each(&block)
        @data.each(&block)
      end

      def has_more?
        cursor = @list_metadata.is_a?(Hash) ? (@list_metadata["after"] || @list_metadata[:after]) : nil
        !cursor.nil? && !cursor.to_s.empty?
      end

      # Fetch the next page when an `after` cursor is present.
      #
      # @return [ListStruct, nil]
      def next_page
        cursor = @list_metadata.is_a?(Hash) ? (@list_metadata["after"] || @list_metadata[:after]) : nil
        return nil if cursor.nil? || cursor.to_s.empty?
        return nil unless @fetch_next

        @fetch_next.call(cursor)
      end

      # Fetch the previous page when a `before` cursor is present.
      #
      # @return [ListStruct, nil]
      def previous_page
        cursor = @list_metadata.is_a?(Hash) ? (@list_metadata["before"] || @list_metadata[:before]) : nil
        return nil if cursor.nil? || cursor.to_s.empty?
        return nil unless @fetch_previous

        @fetch_previous.call(cursor)
      end

      # Iterate over every item across pages.
      #
      # Requires a fetch_next proc wired at construction time. The generator
      # emits this automatically for list endpoints whose spec includes a
      # cursor pagination parameter.
      def auto_paging_each
        return enum_for(:auto_paging_each) unless block_given?

        page = self
        loop do
          page.data.each { |item| yield item }
          next_page = page.next_page
          break if next_page.nil?
          break unless next_page.is_a?(ListStruct)
          break if next_page.data.nil? || next_page.data.empty?

          page = next_page
        end
      end

      # Iterate one page at a time across all pages.
      #
      #   result.each_page do |page|
      #     page.data.each { |item| bulk_insert(item) }
      #   end
      def each_page
        return enum_for(:each_page) unless block_given?

        page = self
        loop do
          yield page
          next_page = page.next_page
          break if next_page.nil?
          break unless next_page.is_a?(ListStruct)
          break if next_page.data.nil? || next_page.data.empty?

          page = next_page
        end
      end
    end
  end
end
