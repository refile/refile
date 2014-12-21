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
      @content_types ||= %w[image/jpeg image/gif image/png] if type == :image
      @errors = []
    end

    def id
      record.send(:"#{name}_id")
    end

    def id=(id)
      record.send(:"#{name}_id=", id) unless record.frozen?
    end

    def get
      if cached?
        cache.get(cache_id)
      elsif id and not id == ""
        store.get(id)
      end
    end

    def valid?(uploadable)
      @errors = []
      @errors << :invalid_extension if @extensions and not valid_extension?(uploadable)
      @errors << :invalid_content_type if @content_types and not valid_content_type?(uploadable)
      @errors << :too_large if cache.max_size and uploadable.size >= cache.max_size
      @errors.empty?
    end

    def cache!(uploadable)
      if valid?(uploadable)
        @cache_file = cache.upload(uploadable)
        @cache_id = @cache_file.id
      elsif @raise_errors
        raise Refile::Invalid, @errors.join(", ")
      end
    end

    def download(url)
      if url and not url == ""
        cache!(RestClient::Request.new(method: :get, url: url, raw_response: true).execute.file)
      end
    rescue RestClient::Exception
      @errors = [:download_failed]
      raise if @raise_errors
    end

    def cache_id=(id)
      @cache_id = id unless @cache_file
    end

    def store!
      if remove?
        delete!
      elsif cached?
        file = store.upload(cache.get(cache_id))
        delete!
        self.id = file.id
      end
    end

    def delete!
      if cached?
        cache.delete(cache_id)
        @cache_id = nil
        @cache_file = nil
      end
      store.delete(id) if id
      self.id = nil
    end

    def remove?
      remove and remove != "" and remove !~ /\A0|false$\z/
    end

  private

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
