module Defile
  class File
    attr_reader :store, :id

    def initialize(store, id)
      @store = store
      @id = id
    end

    def read(*args)
      io.read(*args)
    end

    def eof?
      io.eof?
    end

    def close
      io.close
    end

    def size
      store.size(id)
    end

    def delete
      store.delete(id)
    end

    def exists?
      store.exists?(id)
    end

    def to_io
      io
    end

  private

    def io
      @io ||= store.open(id)
    end
  end
end
