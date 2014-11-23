module Defile
  module Attachment
    def attachment(name, type:, max_size: Float::INFINITY, cache_name: :cache, store_name: :store)
      cache = Defile.backends.fetch(cache_name.to_s)
      store = Defile.backends.fetch(store_name.to_s)

      attr_writer :"#{name}_cache_id"
      attr_accessor :"#{name}_cache_file"

      define_method "#{name}_store_backend" do
        store
      end

      define_method "#{name}_cache_backend" do
        cache
      end

      define_method "#{name}=" do |uploadable|
        file = cache.upload(uploadable)
        send("#{name}_cache_file=", file)
      end

      define_method name do
        id = send("#{name}_id")
        cache_id = send("#{name}_cache_id")

        if cache_id and not cache_id == ""
          cache.get(cache_id)
        elsif id and not id == ""
          store.get(id)
        end
      end

      define_method "#{name}_cache_id" do
        file = send("#{name}_cache_file")
        if file
          file.id
        else
          instance_variable_get(:"@#{name}_cache_id")
        end
      end

      define_method "store_#{name}" do
        cache_id = send("#{name}_cache_id")
        id = send("#{name}_id")

        if cache_id and not cache_id == ""
          file = store.upload(cache.get(cache_id))
          send("#{name}_id=", file.id)
          cache.delete(cache_id)
          send("#{name}_cache_id=", nil)
          send("#{name}_cache_file=", nil)
          store.delete(id) if id
        end
      end
    end
  end
end
