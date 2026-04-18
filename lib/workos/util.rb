# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained runtime
require "cgi"

module WorkOS
  module Util
    # Percent-encode a value for use in a URL path segment (RFC 3986).
    # Unlike CGI.escape, spaces become %20 instead of +.
    def self.encode_path(value)
      str = value.to_s
      raise ArgumentError, "path segment cannot be nil or empty" if str.empty?
      CGI.escape(str).gsub("+", "%20")
    end
  end
end
