module Defile
  module Attachment
    class Attachment
      attr_reader :record, :name, :cache, :store

      def initialize(record, name, type:, max_size:, cache:, store:)
        @record = record
        @name = name
        @cache = Defile.backends.fetch(cache.to_s)
        @store = Defile.backends.fetch(store.to_s)
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
        @cache_file = cache.upload(uploadable)
        @cache_id = @cache_file.id
      end

      attr_reader :cache_id

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
    end

    def attachment(name, type:, max_size: Float::INFINITY, cache: :cache, store: :store)
      attachment = :"#{name}_attachment"

      define_method attachment do
        ivar = :"@#{attachment}"
        instance_variable_get(ivar) or begin
          instance_variable_set(ivar, Attachment.new(self, name, type: type, max_size: max_size, cache: cache, store: store))
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
