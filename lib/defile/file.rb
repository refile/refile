module Defile
  class File
    attr_reader :store, :id

    def initialize(store, id)
      @store = store
      @id = id
    end

    def read
      store.read(id)
    end

    def size
      store.size(id)
    end

    def exists?
      store.exists?(id)
    end
  end
end
