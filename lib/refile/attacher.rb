require "open-uri"

module Refile
  # @api private
  class Attacher
    attr_reader :record, :name, :cache, :store, :options, :errors, :type, :valid_extensions, :valid_content_types
    attr_accessor :remove

    Presence = ->(val) { val if val != "" }

    def initialize(record, name, cache:, store:, raise_errors: true, type: nil, extension: nil, content_type: nil)
      @record = record
      @name = name
      @raise_errors = raise_errors
      @cache = Refile.backends.fetch(cache.to_s)
      @store = Refile.backends.fetch(store.to_s)
      @type = type
      @valid_extensions = [extension].flatten if extension
      @valid_content_types = [content_type].flatten if content_type
      @valid_content_types ||= Refile.types.fetch(type).content_type if type
      @errors = []
      @metadata = {}
    end

    def id
      Presence[read(:id)]
    end

    def size
      Presence[@metadata[:size] || read(:size)]
    end

    def filename
      Presence[@metadata[:filename] || read(:filename)]
    end

    def content_type
      Presence[@metadata[:content_type] || read(:content_type)]
    end

    def cache_id
      Presence[@metadata[:id]]
    end

    def basename
      if filename and extension
        ::File.basename(filename, "." << extension)
      else
        filename
      end
    end

    def extension
      if filename
        Presence[::File.extname(filename).sub(/^\./, "")]
      elsif content_type
        type = MIME::Types[content_type][0]
        type.extensions[0] if type
      end
    end

    def get
      if cache_id
        cache.get(cache_id)
      elsif id
        store.get(id)
      end
    end

    def set(value)
      if value.is_a?(String)
        retrieve!(value)
      elsif value.is_a?(Refile::File)
        retrieve!({id: value.id}.to_json)
      else
        cache!(value)
      end
    end

    def retrieve!(value)
      @metadata = JSON.parse(value, symbolize_names: true) || {}
      write_metadata if cache_id
    rescue JSON::ParserError
    end

    def cache!(uploadable)
      @metadata = {
        size: uploadable.size,
        content_type: Refile.extract_content_type(uploadable),
        filename: Refile.extract_filename(uploadable)
      }
      if valid?
        @metadata[:id] = cache.upload(uploadable).id
        write_metadata
      elsif @raise_errors
        raise Refile::Invalid, @errors.join(", ")
      end
    end

    def download(url)
      unless url.to_s.empty?
        file = open(url)
        @metadata = {
          size: file.meta["content-length"].to_i,
          filename: ::File.basename(file.base_uri.path),
          content_type: file.meta["content-type"]
        }
        if valid?
          @metadata[:id] = cache.upload(file).id
          write_metadata
        elsif @raise_errors
          raise Refile::Invalid, @errors.join(", ")
        end
      end
    rescue OpenURI::HTTPError, RuntimeError => error
      raise if error.is_a?(RuntimeError) and error.message !~ /redirection loop/
      @errors = [:download_failed]
      raise if @raise_errors
    end

    def store!(keep_id = true)
      if remove?
        delete!
        write(:id, nil)
      elsif cache_id
        id = cache_id if keep_id
        file = store.upload(get, id: id)
        delete!
        write(:id, file.id)
      end
      write_metadata
      @metadata = {}
    end

    def delete!
      cache.delete(cache_id) if cache_id
      store.delete(id) if id
      @metadata = {}
    end

    def accept
      if valid_content_types
        valid_content_types.join(",")
      elsif valid_extensions
        valid_extensions.map { |e| ".#{e}" }.join(",")
      end
    end

    def remove?
      remove and remove != "" and remove !~ /\A0|false$\z/
    end

    def present?
      not @metadata.empty?
    end

    def valid?
      @errors = []
      @errors << :invalid_extension if valid_extensions and not valid_extensions.include?(extension)
      @errors << :invalid_content_type if valid_content_types and not valid_content_types.include?(content_type)
      @errors << :too_large if cache.max_size and size and size >= cache.max_size
      @errors.empty?
    end

    def data
      @metadata if valid?
    end

  private

    def read(column)
      m = "#{name}_#{column}"
      value ||= record.send(m) if record.respond_to?(m)
      value
    end

    def write(column, value)
      m = "#{name}_#{column}="
      record.send(m, value) if record.respond_to?(m) and not record.frozen?
    end

    def write_metadata
      write(:size, size)
      write(:content_type, content_type)
      write(:filename, filename)
    end
  end
end
