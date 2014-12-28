module Refile
  # @api private
  class Attacher
    attr_reader :record, :name, :cache, :store, :cache_id, :options, :errors, :type, :extensions, :content_types
    attr_accessor :remove

    def initialize(record, name, cache:, store:, raise_errors: true, type: nil, extension: nil, content_type: nil)
      @record = record
      @name = name
      @raise_errors = raise_errors
      @cache = Refile.backends.fetch(cache.to_s)
      @store = Refile.backends.fetch(store.to_s)
      @type = type
      @extensions = [extension].flatten if extension
      @content_types = [content_type].flatten if content_type
      @content_types ||= Refile.types.fetch(type).content_type if type
      @errors = []
    end

    def id
      read(:id)
    end

    def size
      read(:size)
    end

    def filename
      read(:filename)
    end

    def content_type
      read(:content_type)
    end

    def data
      { content_type: content_type, filename: filename, size: size, id: cache_id }
    end

    def get
      if cached?
        cache.get(cache_id)
      elsif id and not id == ""
        store.get(id)
      end
    end

    def set(value)
      if value.is_a?(String)
        retrieve!(value)
      else
        cache!(value)
      end
    end

    def retrieve!(value)
      data = JSON.parse(value, symbolize_names: true)
      @cache_id = data.delete(:id)
      write_metadata(**data) if @cache_id
    rescue JSON::ParserError
    end

    def cache!(uploadable)
      if valid?(uploadable)
        @cache_id = cache.upload(uploadable).id
        write_metadata(
          size: uploadable.size,
          content_type: Refile.extract_content_type(uploadable),
          filename: Refile.extract_filename(uploadable)
        )
      elsif @raise_errors
        raise Refile::Invalid, @errors.join(", ")
      end
    end

    def download(url)
      if url and not url == ""
        response = RestClient::Request.new(method: :get, url: url, raw_response: true).execute
        cache!(response.file)
        write_metadata(
          size: response.file.size,
          filename: ::File.basename(url),
          content_type: response.headers[:content_type]
        )
      end
    rescue RestClient::Exception
      @errors = [:download_failed]
      raise if @raise_errors
    end

    def store!
      if remove?
        delete!
      elsif cached?
        file = store.upload(cache.get(cache_id))
        delete!(write: false)
        write(:id, file.id)
      end
    end

    def delete!(write: true)
      if cached?
        cache.delete(cache_id)
        @cache_id = nil
      end
      store.delete(id) if id
      write(:id, nil)
      write_metadata if write
    end

    def accept
      if content_types
        content_types.join(",")
      elsif extensions
        extensions.map { |e| ".#{e}" }.join(",")
      end
    end

    def remove?
      remove and remove != "" and remove !~ /\A0|false$\z/
    end

  private

    def valid?(uploadable)
      @errors = []
      @errors << :invalid_extension if @extensions and not valid_extension?(uploadable)
      @errors << :invalid_content_type if @content_types and not valid_content_type?(uploadable)
      @errors << :too_large if cache.max_size and uploadable.size >= cache.max_size
      @errors.empty?
    end

    def read(column)
      m = "#{name}_#{column}"
      record.send(m) if record.respond_to?(m)
    end

    def write(column, value)
      m = "#{name}_#{column}="
      record.send(m, value) if record.respond_to?(m) and not record.frozen?
    end

    def write_metadata(size: nil, content_type: nil, filename: nil)
      write(:size, size)
      write(:content_type, content_type)
      write(:filename, filename)
    end

    def valid_content_type?(uploadable)
      content_type = Refile.extract_content_type(uploadable) or return false
      @content_types.include?(content_type)
    end

    def valid_extension?(uploadable)
      filename = Refile.extract_filename(uploadable) or return false
      extension = ::File.extname(filename).sub(/^\./, "")
      @extensions.include?(extension)
    end

    def cached?
      cache_id and not cache_id == ""
    end
  end
end
