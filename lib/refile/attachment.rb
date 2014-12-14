module Refile
  module Attachment
    # @api private
    class Attachment
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
        record.send(:"#{name}_id=", id)
      end

      def file
        if cached?
          cache.get(cache_id)
        elsif id and not id == ""
          store.get(id)
        end
      end

      def file=(uploadable)
        @cache_file = cache.upload(uploadable)
        @cache_id = @cache_file.id
        @errors = []
      rescue Refile::Invalid
        @errors = [:too_large]
        raise if @options[:raise_errors]
      end

      def download(url)
        if url and not url == ""
          raw_response = RestClient::Request.new(method: :get, url: url, raw_response: true).execute
          self.file = raw_response.file
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

    # Macro which generates accessors for the given column which make it
    # possible to upload and retrieve previously uploaded files through the
    # generated accessors.
    #
    # The +raise_errors+ option controls whether assigning an invalid file
    # should immediately raise an error, or save the error and defer handling
    # it until later.
    #
    # @param [String] name                 Name of the column which accessor are generated for
    # @param [#to_s] cache                 Name of a backend in +Refile.backends+ to use as transient cache
    # @param [#to_s] store                 Name of a backend in +Refile.backends+ to use as permanent store
    # @param [true, false] raise_errors    Whether to raise errors in case an invalid file is assigned
    def attachment(name, cache: :cache, store: :store, raise_errors: true)
      attachment = :"#{name}_attachment"

      define_method attachment do
        ivar = :"@#{attachment}"
        instance_variable_get(ivar) or begin
          instance_variable_set(ivar, Attachment.new(self, name, cache: cache, store: store, raise_errors: raise_errors))
        end
      end

      define_method "#{name}=" do |uploadable|
        send(attachment).file = uploadable
      end

      define_method name do
        send(attachment).file
      end

      define_method "#{name}_cache_id=" do |cache_id|
        send(attachment).cache_id = cache_id
      end

      define_method "#{name}_cache_id" do
        send(attachment).cache_id
      end

      define_method "remove_#{name}=" do |remove|
        send(attachment).remove = remove
      end

      define_method "remove_#{name}" do
        send(attachment).remove
      end

      define_method "remote_#{name}_url=" do |url|
        send(attachment).download(url)
      end

      define_method "remote_#{name}_url" do
      end
    end
  end
end
