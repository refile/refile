module Defile
  class File
    attr_reader :store, :id

    def initialize(store, id)
      @store = store
      @id = id
    end

    def read(*args)
      fd.read(*args)
    end

    def eof?
      fd.eof?
    end

    def close
      fd.close
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
      fd
    end

  private

    def fd
      @fd ||= store.open(id)
    end
  end
end
