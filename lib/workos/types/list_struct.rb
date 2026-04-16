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

      attr_accessor :data, :list_metadata, :fetch_next, :filters

      def initialize(data:, list_metadata:, fetch_next: nil, filters: {})
        @data = data || []
        @list_metadata = list_metadata || {}
        @fetch_next = fetch_next
        @filters = filters
      end

      def each(&block)
        @data.each(&block)
      end

      def has_more?
        cursor = @list_metadata.is_a?(Hash) ? (@list_metadata["after"] || @list_metadata[:after]) : nil
        !cursor.nil? && !cursor.to_s.empty?
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
          break unless page.fetch_next

          next_page = page.fetch_next.call(page.list_metadata)
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
          break unless page.fetch_next

          next_page = page.fetch_next.call(page.list_metadata)
          break if next_page.nil?
          break unless next_page.is_a?(ListStruct)
          break if next_page.data.nil? || next_page.data.empty?

          page = next_page
        end
      end
    end
  end
end
