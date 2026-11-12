# typed: true

# @oagen-ignore-file
#
# Constants from other gems that lib/ and the provider gems refer to. The
# type check only needs them to resolve; this repo does not check in
# generated RBI for its dependencies. Used by `srb tc` only; nothing here is
# a signature of this gem.

module Zeitwerk
  class Loader; end
end

module JWT
  class DecodeError < StandardError; end
  class ExpiredSignature < DecodeError; end
  class IncorrectAlgorithm < DecodeError; end
  class VerificationError < DecodeError; end
end

module Aws
  module Errors
    class ServiceError < RuntimeError; end
    class MissingRegionError < ArgumentError; end
    class InvalidRegionError < ArgumentError; end
  end

  module STS
    class Client; end
  end
end
