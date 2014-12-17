module Refile
  # @api private
  class Attacher
    attr_reader :record, :name, :cache, :store, :cache_id, :options, :errors
    attr_accessor :remove

    def initialize(record, name, **options)
      @record = record
      @name = name
      @options = options
      @cache = Refile.backends.fetch(@options[:cache].to_s)
      @store = Refile.backends.fetch(@options[:store].to_s)
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

    def cache!(uploadable)
      @cache_file = cache.upload(uploadable)
      @cache_id = @cache_file.id
      @errors = []
    rescue Refile::Invalid
      @errors = [:too_large]
      raise if @options[:raise_errors]
    end

    def download(url)
      if url and not url == ""
        cache!(RestClient::Request.new(method: :get, url: url, raw_response: true).execute.file)
      end
    rescue RestClient::Exception
      @errors = [:download_failed]
      raise if @options[:raise_errors]
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

    def cached?
      cache_id and not cache_id == ""
    end
  end
end
