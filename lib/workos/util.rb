# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained runtime
require "cgi"

module WorkOS
  module Util
    # Percent-encode a value for use in a URL path segment (RFC 3986).
    # Unlike CGI.escape, spaces become %20 instead of +.
    def self.encode_path(value)
      CGI.escape(value.to_s).gsub("+", "%20")
    end
  end
end
