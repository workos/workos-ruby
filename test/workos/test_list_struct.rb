# frozen_string_literal: true

require "test_helper"

class ListStructTest < Minitest::Test
  def test_next_page_uses_after_cursor
    next_page = WorkOS::Types::ListStruct.new(data: [2], list_metadata: {})
    list = WorkOS::Types::ListStruct.new(
      data: [1],
      list_metadata: {"after" => "cursor_after"},
      fetch_next: lambda { |cursor|
        assert_equal "cursor_after", cursor
        next_page
      }
    )

    assert_same next_page, list.next_page
  end

  def test_previous_page_uses_before_cursor
    previous_page = WorkOS::Types::ListStruct.new(data: [0], list_metadata: {})
    list = WorkOS::Types::ListStruct.new(
      data: [1],
      list_metadata: {"before" => "cursor_before"},
      fetch_previous: lambda { |cursor|
        assert_equal "cursor_before", cursor
        previous_page
      }
    )

    assert_same previous_page, list.previous_page
  end

  def test_next_page_returns_nil_without_cursor
    list = WorkOS::Types::ListStruct.new(data: [1], list_metadata: {}, fetch_next: lambda { |_cursor| flunk("should not fetch") })

    assert_nil list.next_page
  end
end
