require "uri"
require "fileutils"
require "tempfile"
require "logger"
require "mime/types"

module Refile
  # @api private
  class Invalid < StandardError; end

  # @api private
  class InvalidID < Invalid; end

  # @api private
  class Confirm < StandardError
    def message
      "are you sure? this will remove all files in the backend, call as \
      `clear!(:confirm)` if you're sure you want to do this"
    end
  end

  class << self
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

    # Logger that should be used by rack application
    #
    # @return [Logger]
    attr_accessor :logger

    # Value for Access-Control-Allow-Origin header
    #
    # @return [String]
    attr_accessor :allow_origin

    # Value for Cache-Control: max-age=<value in seconds> header
    #
    # @return [Integer]
    attr_accessor :content_max_age

    # Where should the rack application be mounted? The default is 'attachments'.
    #
    # @return [String]
    attr_accessor :mount_point

    # Should the rack application be automounted in a Rails app?
    #
    # If set to false then Refile.app should be mounted in the Rails application
    # routes.rb with the options `at: Refile.mount_point, as: :refile_app`
    #
    # The default is true.
    #
    # @return [Boolean]
    attr_accessor :automount

    # Value for generating signed attachment urls to protect from DoS
    #
    # @return [String]
    attr_accessor :secret_key

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

    # A global registry of types. Currently, types are simply aliases for a set
    # of content types, but their functionality may expand in the future.
    #
    # @return [Hash{Symbol => Refile::Type}]
    def types
      @types ||= {}
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
    # @return [void]
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

    # Extract the filename from an uploadable object. If the filename cannot be
    # determined, this method will return `nil`.
    #
    # @param [IO] uploadable    The uploadable object to extract the filename from
    # @return [String, nil]     The extracted filename
    def extract_filename(uploadable)
      path = if uploadable.respond_to?(:original_filename)
        uploadable.original_filename
      elsif uploadable.respond_to?(:path)
        uploadable.path
      end
      ::File.basename(path) if path
    end

    # Extract the content type from an uploadable object. If the content type
    # cannot be determined, this method will return `nil`.
    #
    # @param [IO] uploadable    The uploadable object to extract the content type from
    # @return [String, nil]     The extracted content type
    def extract_content_type(uploadable)
      if uploadable.respond_to?(:content_type)
        uploadable.content_type
      else
        filename = extract_filename(uploadable)
        if filename
          content_type = MIME::Types.of(filename).first
          content_type.to_s if content_type
        end
      end
    end

    # Generate a URL to an attachment. This method receives an instance of a
    # class which has used the {Refile::Attachment#attachment} macro to
    # generate an attachment column, and the name of this column, and based on
    # this generates a URL to a {Refile::App}.
    #
    # Optionally the name of a processor and arguments to it can be appended.
    #
    # If the filename option is not given, the filename is taken from the
    # metadata stored in the attachment, or eventually falls back to the
    # `name`.
    #
    # The host defaults to {Refile.host}, which is useful for serving all
    # attachments from a CDN. You can also override the host via the `host`
    # option.
    #
    # Returns `nil` if there is no file attached.
    #
    # @example
    #   attachment_url(@post, :document)
    #
    # @example With processor
    #   attachment_url(@post, :image, :fill, 300, 300, format: "jpg")
    #
    # @param [Refile::Attachment] object   Instance of a class which has an attached file
    # @param [Symbol] name                 The name of the attachment column
    # @param [String, nil] filename        The filename to be appended to the URL
    # @param [String, nil] format          A file extension to be appended to the URL
    # @param [String, nil] host            Override the host
    # @param [String, nil] prefix          Adds a prefix to the URL if the application is not mounted at root
    # @return [String, nil]                The generated URL
    def attachment_url(object, name, *args, prefix: nil, filename: nil, format: nil, host: nil)
      attacher = object.send(:"#{name}_attacher")
      file = attacher.get
      return unless file

      host ||= Refile.host
      prefix ||= Refile.mount_point
      filename ||= attacher.basename || name.to_s
      format ||= attacher.extension

      backend_name = Refile.backends.key(file.backend)

      filename = Rack::Utils.escape(filename)
      filename << "." << format.to_s if format

      uri = URI(host.to_s)
      base_path = ::File.join("", backend_name, *args.map(&:to_s), file.id.to_s, filename)
      uri.path = ::File.join("", *prefix, token(base_path), base_path)

      uri.to_s
    end

    # Generate a signature for a given path concatenated with the configured secret token.
    #
    # Raises an error if no secret token is configured.
    #
    # @example
    #   Refile.token('/store/f5f2e4/document.pdf')
    #
    # @param [String] path          The path to generate a token for
    # @raise [RuntimeError]         If {Refile.secret_key} is not set
    # @return [String, nil]         The generated token
    def token(path)
      if secret_key.nil?
        error = "Refile.secret_key was not set.\n\n"
        error << "Please add the following to your Refile configuration and restart your application:\n\n"
        error << "```\nRefile.secret_key = '#{SecureRandom.hex(64)}'\n```\n\n"

        raise error
      end

      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), secret_key, path)
    end

    # Check if the given token is a valid token for the given path.
    #
    # @example
    #   Refile.valid_token?('/store/f5f2e4/document.pdf', 'abcd1234')
    #
    # @param [String] path          The path to check validity for
    # @param [String] token         The token to check
    # @raise [RuntimeError]         If {Refile.secret_key} is not set
    # @return [Boolean]             Whether the token is valid
    def valid_token?(path, token)
      expected = Digest::SHA1.hexdigest(token(path))
      actual = Digest::SHA1.hexdigest(token)

      expected == actual
    end
  end

  require "refile/version"
  require "refile/signature"
  require "refile/type"
  require "refile/backend_macros"
  require "refile/attacher"
  require "refile/attachment"
  require "refile/random_hasher"
  require "refile/file"
  require "refile/custom_logger"
  require "refile/app"
  require "refile/backend/file_system"
end

Refile.configure do |config|
  config.direct_upload = ["cache"]
  config.allow_origin = "*"
  config.logger = Logger.new(STDOUT)
  config.mount_point = "attachments"
  config.automount = true
  config.content_max_age = 60 * 60 * 24 * 365
  config.types[:image] = Refile::Type.new(:image, content_type: %w[image/jpeg image/gif image/png])
end
