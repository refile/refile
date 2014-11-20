module Defile
  module Attachment
    def attachment(name, type:, max_size: Float::INFINITY, cache: nil, store: nil)
      cache ||= Defile.cache
      store ||= Defile.store

      attr_accessor :"#{name}_cache_id"

      define_method "#{name}=" do |uploadable|
        file = cache.upload(uploadable)
        send("#{name}_cache_id=", file.id)
      end

      define_method name do
        id = send("#{name}_id")
        cache_id = send("#{name}_cache_id")

        if cache_id
          cache.get(cache_id)
        elsif id
          store.get(id)
        end
      end

      define_method "store_#{name}" do
        cache_id = send("#{name}_cache_id")
        id = send("#{name}_id")

        if cache_id
          file = store.upload(cache.get(cache_id))
          send("#{name}_id=", file.id)
          cache.delete(cache_id)
          send("#{name}_cache_id=", nil)
          store.delete(id) if id
        end
      end
    end
  end
end
