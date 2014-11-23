module Defile
  module Attachment
    IMAGE_TYPES = %w[jpg jpeg gif png]

    class Attachment
      attr_reader :record, :name, :cache, :store, :cache_id, :options

      def initialize(record, name, **options)
        @record = record
        @name = name
        @options = options
        @cache = Defile.backends.fetch(@options[:cache].to_s)
        @store = Defile.backends.fetch(@options[:store].to_s)
        @errors = []
      end

      def id
        record.send(:"#{name}_id")
      end

      def id=(id)
        record.send(:"#{name}_id=", id)
      end

      def file
        if cache_id and not cache_id == ""
          cache.get(cache_id)
        elsif id and not id == ""
          store.get(id)
        end
      end

      def file=(uploadable)
        if valid_size?(uploadable)
          @cache_file = cache.upload(uploadable)
          @cache_id = @cache_file.id
          @errors = []
        else
          @errors = [:too_large]
          if @options[:raise_errors]
            raise Defile::Invalid, "uploaded file is too large"
          end
        end
      end

      def cache_id=(id)
        @cache_id = id unless @cache_file
      end

      def store!
        if cache_id and not cache_id == ""
          file = store.upload(cache.get(cache_id))
          cache.delete(cache_id)
          store.delete(id) if id
          self.id = file.id
          @cache_id = nil
          @cache_file = nil
        end
      end

      def errors
        @errors
      end

    private

      def valid_size?(uploadable)
        if @options[:max_size]
          uploadable.size <= @options[:max_size]
        else
          true
        end
      end
    end

    def attachment(name, max_size: Float::INFINITY, cache: :cache, store: :store, raise_errors: true)
      attachment = :"#{name}_attachment"

      define_method attachment do
        ivar = :"@#{attachment}"
        instance_variable_get(ivar) or begin
          instance_variable_set(ivar, Attachment.new(self, name, max_size: max_size, cache: cache, store: store, raise_errors: raise_errors))
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
    end
  end
end
