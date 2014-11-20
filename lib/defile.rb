require "fileutils"

module Defile
  class << self
    attr_accessor :read_chunk_size

    def configure
      yield self
    end

    def verify_uploadable(uploadable)
      [:size, :to_io].each do |m|
        raise ArgumentError, "#{uploadable} does not respond to `#{m}` cannot upload" unless uploadable.respond_to?(m)
      end
      true
    end
  end

  require "defile/version"
  require "defile/random_hasher"
  require "defile/file"
  require "defile/store"
  require "defile/store/file_store"
end

Defile.configure do |config|
  # FIXME: what is a sane default here? This is a little less than a
  # memory page, which seemed like a good default, is there a better
  # one?
  config.read_chunk_size = 3000
end
