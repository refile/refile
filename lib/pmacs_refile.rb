require "uri"
require "fileutils"
require "tempfile"
require "rest_client"
require "logger"
require "mime/types"

module PmacsRefile
  # @api private
  class Invalid < StandardError; end

  # @api private
  class InvalidID < Invalid; end

  # @api private
  class InvalidMaxSize < Invalid; end

  # @api private
  class InvalidFile < Invalid; end

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
    # @return [PmacsRefile::App, nil]
    attr_accessor :app

    # The host name of a CDN distribution that the Rack application can be
    # reached at. If not set, PmacsRefile will use an absolute URL without hostname.
    # It is strongly recommended to run PmacsRefile behind a CDN and to set this to
    # the hostname of the CDN distribution.
    #
    # The `cdn_host` setting is used when retrieving files, but not when
    # uploading new files, since uploads should normally not go through the
    # CDN.
    #
    # A protocol relative URL is recommended for this value.
    #
    # @return [String, nil]
    attr_accessor :cdn_host

    # The host name that the Rack application can be reached at. If not set,
    # PmacsRefile will use an absolute URL without hostname. You should only change
    # this setting if you are running the PmacsRefile app on a different domain
    # than your main application.
    #
    # If you are simply running the PmacsRefile app behind a CDN you'll want to
    # change {PmacsRefile.cdn_host} instead.
    #
    # The difference between {PmacsRefile.app_host} and {PmacsRefile.cdn_host} is that the
    # latter only affects URLs generated by {PmacsRefile.file_url} and the
    # {PmacsRefile::AttachmentHelper#attachment_url} and
    # {PmacsRefile::AttachmentHelper#attachment_image_tag} helpers, whereas the
    # former also affects {PmacsRefile.upload_url}, {PmacsRefile.presign_url} and the
    # {PmacsRefile::AttachmentHelper#attachment_field} helper.
    #
    # @return [String, nil]
    attr_accessor :app_host

    # @deprecated use {PmacsRefile.cdn_host} instead
    def host
      warn "PmacsRefile.host is deprecated, please use PmacsRefile.cdn_host instead"
      cdn_host
    end

    # @deprecated use {PmacsRefile.cdn_host} instead
    def host=(host)
      warn "PmacsRefile.host is deprecated, please use PmacsRefile.cdn_host instead"
      self.cdn_host = host
    end

    # A list of names which identify backends in the global backend registry.
    # The Rack application allows POST requests to only the backends specified
    # in this config option. This defaults to `["cache"]`, only allowing direct
    # uploads to the cache backend.
    #
    # @return [Array[String], :all]
    attr_accessor :allow_uploads_to

    # A list of names which identify backends in the global backend registry.
    # The Rack application allows GET requests to only the backends specified
    # in this config option. This defaults to `:all`, allowing files from all
    # backends to be downloaded.
    #
    # @return [Array[String], :all]
    attr_accessor :allow_downloads_from

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
    # If set to false then PmacsRefile.app should be mounted in the Rails application
    # routes.rb with the options `at: PmacsRefile.mount_point, as: :refile_app`
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
    # @return [Hash{Symbol => PmacsRefile::Type}]
    def types
      @types ||= {}
    end

    # Adds a processor. The processor must respond to `call`, both receiving
    # and returning an IO-like object. Alternatively a block can be given to
    # this method which also receives and returns an IO-like object.
    #
    # An IO-like object is recommended to be an instance of the `IO` class or
    # one of its subclasses, like `File` or a `StringIO`, or a `PmacsRefile::File`.
    # It can also be any other object which responds to `size`, `read`, `eof`?
    # `rewind` and `close` and mimics the behaviour of IO objects for these
    # methods.
    #
    # @example With processor class
    #   class Reverse
    #     def call(file)
    #       StringIO.new(file.read.reverse)
    #     en
    #   end
    #   PmacsRefile.processor(:reverse, Reverse)
    #
    # @example With block
    #   PmacsRefile.processor(:reverse) do |file|
    #     StringIO.new(file.read.reverse)
    #   end
    #
    # @param [#to_s] name           The name of the processor
    # @param [Proc, nil] processor  The processor, must respond to `call` and.
    # @yield [PmacsRefile::File]         The file to modify
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

    # Yield the PmacsRefile module as a convenience for configuring multiple
    # config options at once.
    #
    # @yield PmacsRefile
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

    # Generates a URL to the PmacsRefile application.
    #
    # The host defaults to {PmacsRefile.app_host}. You can also override the host via
    # the `host` option. Normally the PmacsRefile app will not be mounted at the
    # root but rather at some other path, the `prefix` option allows you to
    # override this setting, and if not set it will fall back to
    # {PmacsRefile.mount_point}.
    #
    # @example
    #   PmacsRefile.app_url
    #
    # @example With host and prefix
    #   PmacsRefile.app_url(host: "http://some.domain", prefix: "/refile")
    #
    # @param [String, nil] host            Override the host
    # @param [String, nil] prefix          Adds a prefix to the URL if the application is not mounted at root
    # @return [String]                     The generated URL
    def app_url(host: nil, prefix: nil)
      host ||= PmacsRefile.app_host
      prefix ||= PmacsRefile.mount_point

      uri = URI(host.to_s)
      uri.path = prefix || "/"
      uri.to_s
    end

    # Receives a {PmacsRefile::File} and generates a URL to it.
    #
    # Optionally the name of a processor and arguments to it can be appended.
    #
    # The `filename` option must be given.
    #
    # The host defaults to {PmacsRefile.cdn_host}, which is useful for serving all
    # attachments from a CDN. You can also override the host via the `host`
    # option.
    #
    # Returns `nil` if the supplied file is `nil`.
    #
    # @example
    #   PmacsRefile.file_url(PmacsRefile.store.get(id))
    #
    # @example With processor
    #   PmacsRefile.file_url(PmacsRefile.store.get(id), :image, :fill, 300, 300, format: "jpg")
    #
    # @param [PmacsRefile::File] file           The file to generate a URL for
    # @param [String] filename             The filename to be appended to the URL
    # @param [String, nil] format          A file extension to be appended to the URL
    # @param [String, nil] host            Override the host
    # @param [String, nil] prefix          Adds a prefix to the URL if the application is not mounted at root
    # @param [String, nil] expires_at      Adds a sulfix to the URL that sets the expiration time of the URL
    # @param [String, nil] force_download  Adds a sulfix to the URL to force the download of the file when URL is accessed
    # @return [String, nil]                The generated URL
    def file_url(file, *args, expires_at: nil, host: nil, prefix: nil, filename:, format: nil, force_download: nil)
      return unless file

      host ||= PmacsRefile.cdn_host
      backend_name = PmacsRefile.backends.key(file.backend)

      filename = Rack::Utils.escape(filename)
      filename << "." << format.to_s if format && !filename.downcase.end_with?(format.to_s.downcase)

      base_path = ::File.join("", backend_name, *args.map(&:to_s), file.id.to_s, filename)
      if expires_at
        base_path += "?expires_at=#{expires_at.to_i}" # UNIX timestamp
      end

      base_path += "?force_download=true" if force_download

      ::File.join(app_url(prefix: prefix, host: host), token(base_path), base_path)
    end

    # Receives a PmacsRefile backend and returns a URL to the PmacsRefile application
    # where files can be uploaded.
    #
    # @example
    #   PmacsRefile.upload_url(PmacsRefile.store)
    #
    # @param [PmacsRefile::Backend] backend     The backend to generate a URL for
    # @param [String, nil] host            Override the host
    # @param [String, nil] prefix          Adds a prefix to the URL if the application is not mounted at root
    # @return [String]                     The generated URL
    def upload_url(backend, host: nil, prefix: nil)
      backend_name = PmacsRefile.backends.key(backend)

      ::File.join(app_url(host: host, prefix: prefix), backend_name)
    end

    # Receives a PmacsRefile backend and returns a URL to the PmacsRefile application
    # where a presign object for the backend can be retrieved.
    #
    # @example
    #   PmacsRefile.upload_url(PmacsRefile.store)
    #
    # @param [PmacsRefile::Backend] backend     The backend to generate a URL for
    # @param [String, nil] host            Override the host
    # @param [String, nil] prefix          Adds a prefix to the URL if the application is not mounted at root
    # @return [String]                     The generated URL
    def presign_url(backend, host: nil, prefix: nil)
      ::File.join(upload_url(backend, host: host, prefix: prefix), "presign")
    end

    # Generate a URL to an attachment. Receives an instance of a class which
    # has used the {PmacsRefile::Attachment#attachment} macro to generate an
    # attachment column, and the name of this column, and based on this
    # generates a URL to a {PmacsRefile::App}.
    #
    # Optionally the name of a processor and arguments to it can be appended.
    #
    # If the filename option is not given, the filename is taken from the
    # metadata stored in the attachment, or eventually falls back to the
    # `name`.
    #
    # The host defaults to {PmacsRefile.cdn_host}, which is useful for serving all
    # attachments from a CDN. You can also override the host via the `host`
    # option.
    #
    # Returns `nil` if there is no file attached.
    #
    # @example
    #   PmacsRefile.attachment_url(@post, :document)
    #
    # @example With processor
    #   PmacsRefile.attachment_url(@post, :image, :fill, 300, 300, format: "jpg")
    #
    # @param [PmacsRefile::Attachment] object   Instance of a class which has an attached file
    # @param [Symbol] name                 The name of the attachment column
    # @param [String, nil] filename        The filename to be appended to the URL
    # @param [String, nil] format          A file extension to be appended to the URL
    # @param [String, nil] host            Override the host
    # @param [String, nil] prefix          Adds a prefix to the URL if the application is not mounted at root
    # @param [String, nil] expires_at      Adds a sulfix to the URL that sets the expiration time of the URL
    # @param [String, nil] force_download  Adds a sulfix to the URL to force the download of the file when URL is accessed
    # @return [String, nil]                The generated URL
    def attachment_url(object, name, *args, expires_at: nil, host: nil, prefix: nil, filename: nil, format: nil, force_download: nil)
      attacher = object.send(:"#{name}_attacher")
      file = attacher.get
      return unless file

      filename ||= attacher.basename || name.to_s
      format ||= attacher.extension

      file_url(file, *args, expires_at: expires_at, host: host, prefix: prefix, filename: filename, format: format, force_download: force_download)
    end

    # Receives an instance of a class which has used the
    # {PmacsRefile::Attachment#attachment} macro to generate an attachment column,
    # and the name of this column, and based on this generates a URL to a
    # {PmacsRefile::App} where files can be uploaded.
    #
    # @example
    #   PmacsRefile.attachment_upload_url(@post, :document)
    #
    # @param [PmacsRefile::Attachment] object   Instance of a class which has an attached file
    # @param [Symbol] name                 The name of the attachment column
    # @param [String, nil] host            Override the host
    # @param [String, nil] prefix          Adds a prefix to the URL if the application is not mounted at root
    # @return [String]                     The generated URL
    def attachment_upload_url(object, name, host: nil, prefix: nil)
      backend = object.send(:"#{name}_attachment_definition").cache

      upload_url(backend, host: host, prefix: prefix)
    end

    # Receives an instance of a class which has used the
    # {PmacsRefile::Attachment#attachment} macro to generate an attachment column,
    # and the name of this column, and based on this generates a URL to a
    # {PmacsRefile::App} where a presign object for the backend can be retrieved.
    #
    # @example
    #   PmacsRefile.attachment_presign_url(@post, :document)
    #
    # @param [PmacsRefile::Attachment] object   Instance of a class which has an attached file
    # @param [Symbol] name                 The name of the attachment column
    # @param [String, nil] host            Override the host
    # @param [String, nil] prefix          Adds a prefix to the URL if the application is not mounted at root
    # @return [String]                     The generated URL
    def attachment_presign_url(object, name, host: nil, prefix: nil)
      backend = object.send(:"#{name}_attachment_definition").cache

      presign_url(backend, host: host, prefix: prefix)
    end

    # Generate a signature for a given path concatenated with the configured secret token.
    #
    # Raises an error if no secret token is configured.
    #
    # @example
    #   PmacsRefile.token('/store/f5f2e4/document.pdf')
    #
    # @param [String] path          The path to generate a token for
    # @raise [RuntimeError]         If {PmacsRefile.secret_key} is not set
    # @return [String, nil]         The generated token
    def token(path)
      if secret_key.nil?
        error = "PmacsRefile.secret_key was not set.\n\n"
        error << "Please add the following to your PmacsRefile configuration and restart your application:\n\n"
        error << "```\nPmacsRefile.secret_key = '#{SecureRandom.hex(64)}'\n```\n\n"

        raise error
      end

      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), secret_key, path)
    end

    # Check if the given token is a valid token for the given path.
    #
    # @example
    #   PmacsRefile.valid_token?('/store/f5f2e4/document.pdf', 'abcd1234')
    #
    # @param [String] path          The path to check validity for
    # @param [String] token         The token to check
    # @raise [RuntimeError]         If {PmacsRefile.secret_key} is not set
    # @return [Boolean]             Whether the token is valid
    def valid_token?(path, token)
      expected = Digest::SHA1.hexdigest(token(path))
      actual = Digest::SHA1.hexdigest(token)

      expected == actual
    end

    # @api private
    def parse_json(data, *args)
      JSON.parse(data.to_s, *args)
    rescue JSON::ParserError
      nil
    end
  end

  require "refile/version"
  require "refile/signature"
  require "refile/type"
  require "refile/backend_macros"
  require "refile/attachment_definition"
  require "refile/attacher"
  require "refile/attachment"
  require "refile/random_hasher"
  require "refile/file"
  require "refile/custom_logger"
  require "refile/app"
  require "refile/backend/file_system"
end

PmacsRefile.configure do |config|
  config.allow_uploads_to = ["cache"]
  config.allow_downloads_from = :all
  config.allow_origin = "*"
  config.logger = Logger.new(STDOUT) unless ENV["RACK_ENV"] == "test"
  config.mount_point = "/attachments"
  config.automount = true
  config.content_max_age = 60 * 60 * 24 * 365
  config.types[:image] = PmacsRefile::Type.new(:image, content_type: %w[image/jpeg image/gif image/png])
end