# frozen_string_literal: true

# @oagen-ignore-file
$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "minitest/autorun"
require "socket"
require "workos-workload-identity-gcp"

# Tests talk to a mock on 127.0.0.1; a developer's proxy must not see them.
%w[http_proxy HTTP_PROXY https_proxy HTTPS_PROXY].each { |name| ENV.delete(name) }

# A local HTTP mock that records exactly what arrived on the wire: the raw
# request target (so percent-encoding can be asserted) and the headers.
class MockServer
  Request = Struct.new(:method, :target, :headers)

  attr_reader :requests

  # The block receives each Request and returns [status, headers, body].
  def initialize(&responder)
    @responder = responder
    @requests = []
    @server = TCPServer.new("127.0.0.1", 0)
    @thread = Thread.new { loop { handle(@server.accept) } }
    @thread.report_on_exception = false
  end

  def url
    "http://127.0.0.1:#{@server.addr[1]}"
  end

  def close
    @thread.kill
    @thread.join
    @server.close
  end

  private

  def handle(socket)
    method, target, = socket.gets.to_s.split(" ")
    headers = {}
    while (line = socket.gets) && line != "\r\n"
      name, value = line.chomp.split(": ", 2)
      headers[name.downcase] = value
    end
    request = Request.new(method, target, headers)
    @requests << request

    status, response_headers, body = @responder.call(request)
    head = {"Content-Length" => body.bytesize.to_s, "Connection" => "close"}.merge(response_headers)
    socket.write("HTTP/1.1 #{status} Mock\r\n")
    head.each { |name, value| socket.write("#{name}: #{value}\r\n") }
    socket.write("\r\n#{body}")
  ensure
    socket.close
  end
end
