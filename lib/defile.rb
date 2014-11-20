require "fileutils"

module Defile
  class << self
    attr_accessor :read_chunk_size

    def configure
      yield self
    end

    def verify_uploadable(uploadable)
      unless uploadable.respond_to?(:size)
        raise ArgumentError, "can not determine size of #{uploadable}, it does not respond to `size` cannot upload"
      end
      unless uploadable.respond_to?(:to_io) or uploadable.respond_to?(:stream)
        raise ArgumentError, "#{uploadable} does not respond to `stream` and cannot be cast to IO via `to_io` cannot upload"
      end
      true
    end

    def stream(uploadable)
      verify_uploadable(uploadable)

      if uploadable.respond_to?(:stream)
        uploadable.stream
      else
        # FIXME: do we really want to use `Defile::Stream`? This could
        # potentially close FDs which we don't want to close yet.
        Defile::Stream.new(uploadable.to_io).each
      end
    end
  end

  require "defile/version"
  require "defile/random_hasher"
  require "defile/stream"
  require "defile/file"
  require "defile/backend/file_system"
end

Defile.configure do |config|
  # FIXME: what is a sane default here? This is a little less than a
  # memory page, which seemed like a good default, is there a better
  # one?
  config.read_chunk_size = 3000
end
