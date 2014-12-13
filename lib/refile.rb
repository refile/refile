require "uri"
require "fileutils"
require "tempfile"
require "rest_client"

module Refile
  class Invalid < StandardError; end

  class << self

    # The number of bytes to read when files are streamed. Refile
    # uses this in a couple of places where files should be streamed
    # in a memory efficient way instead of reading the entire file into
    # memory at once. The default value of this is `3000`.
    #
    # @return [Fixnum]
    attr_accessor :read_chunk_size

    # A shortcut to the instance of the Rack application. This should be
    # set when the application is initialized. `refile/rails` sets this
    # value.
    #
    # @return [Refile::App, nil]
    attr_accessor :app

    # The host name that the Rack application can be reached at. If not set,
    # Refile will use an absolute URL without hostname. It is strongly
    # recommended to run Refile behind a CDN and to set this to the hostname of
    # the CDN distribution. A protocol relative URL is recommended for this
    # value.
    #
    # @return [String, nil]
    attr_accessor :host

    # A list of names which identify backends in the global backend registry.
    # The Rack application allows POST requests to only the backends specified
    # in this config option. This defaults to `["cache"]`, only allowing direct
    # uploads to the cache backend.
    #
    # @return [Array[String]]
    attr_accessor :direct_upload

    # A global registry of backends.
    #
    # @return [Hash{String => Backend}]
    def backends
      @backends ||= {}
    end

    # A global registry of processors. These will be used by the Rack
    # application to manipulate files prior to serving them up to the user,
    # based on options sent trough the URL. This can be used for example to
    # resize images or to convert files to another file format.
    #
    # @return [Hash{String => Proc}]
    def processors
      @processors ||= {}
    end

    # Adds a processor. The processor must respond to `call`, both receiving
    # and returning an IO-like object. Alternatively a block can be given to
    # this method which also receives and returns an IO-like object.
    #
    # An IO-like object is recommended to be an instance of the `IO` class or
    # one of its subclasses, like `File` or a `StringIO`, or a `Refile::File`.
    # It can also be any other object which responds to `size`, `read`, `eof`?
    # and `close` and mimics the behaviour of IO objects for these methods.
    #
    # @example With processor class
    #   class Reverse
    #     def call(file)
    #       StringIO.new(file.read.reverse)
    #     en
    #   end
    #   Refile.processor(:reverse, Reverse)
    #
    # @example With block
    #   Refile.processor(:reverse) do |file|
    #     StringIO.new(file.read.reverse)
    #   end
    #
    # @param [#to_s] name           The name of the processor
    # @param [Proc, nil] processor  The processor, must respond to `call` and.
    # @yield [Refile::File]         The file to modify
    # @yieldreturn [IO]             An IO-like object representing the processed file
    def processor(name, processor = nil, &block)
      processor ||= block
      processors[name.to_s] = processor
    end

    # A shortcut to retrieving the backend named "store" from the global
    # registry.
    #
    # @return [Backend]
    def store
      backends["store"]
    end

    # A shortcut to setting the backend named "store" in the global registry.
    #
    # @param [Backend] backend
    def store=(backend)
      backends["store"] = backend
    end

    # A shortcut to retrieving the backend named "cache" from the global
    # registry.
    #
    # @return [Backend]
    def cache
      backends["cache"]
    end

    # A shortcut to setting the backend named "cache" in the global registry.
    #
    # @param [Backend] backend
    def cache=(backend)
      backends["cache"] = backend
    end

    # Yield the Refile module as a convenience for configuring multiple
    # config options at once.
    #
    # @yield Refile
    def configure
      yield self
    end

    # Verify that the given uploadable is indeed a valid uploadable. This
    # method is used by backends as a sanity check, you should not have to use
    # this method unless you are writing a backend.
    #
    # @param [IO] uploadable    The uploadable object to verify
    # @param [Fixnum] max_size  The maximum size of the uploadable object
    # @raise [ArgumentError]    If the uploadable is not an IO-like object
    # @raise [Refile::Invalid]  If the uploadable's size is too large
    # @return [true]            Always returns true if it doesn't raise
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
