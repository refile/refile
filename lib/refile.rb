require "uri"
require "fileutils"
require "tempfile"
require "rest_client"

module Refile
  class Invalid < StandardError; end

  class << self
    attr_accessor :read_chunk_size, :app, :host, :direct_upload
    attr_writer :store, :cache

    def backends
      @backends ||= {}
    end

    def processors
      @processors ||= {}
    end

    def processor(name, processor = nil, &block)
      processor ||= block
      processors[name.to_s] = processor
    end

    def store
      backends["store"]
    end

    def store=(backend)
      backends["store"] = backend
    end

    def cache
      backends["cache"]
    end

    def cache=(backend)
      backends["cache"] = backend
    end

    def configure
      yield self
    end

    def verify_uploadable(uploadable, max_size)
      [:size, :read, :eof?, :close].each do |m|
        unless uploadable.respond_to?(m)
          raise ArgumentError, "does not respond to `#{m}`."
        end
      end
      if max_size and uploadable.size > max_size
        raise Refile::Invalid, "#{uploadable.inspect} is too large"
      end
      true
    end
  end

  require "refile/version"
  require "refile/attachment"
  require "refile/random_hasher"
  require "refile/file"
  require "refile/app"
  require "refile/backend/file_system"
end

Refile.configure do |config|
  # FIXME: what is a sane default here? This is a little less than a
  # memory page, which seemed like a good default, is there a better
  # one?
  config.read_chunk_size = 3000
  config.direct_upload = ["cache"]
end
