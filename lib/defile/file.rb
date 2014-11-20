module Defile
  class File
    attr_reader :backend, :id

    def initialize(backend, id)
      @backend = backend
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
      backend.size(id)
    end

    def delete
      backend.delete(id)
    end

    def exists?
      backend.exists?(id)
    end

    def to_io
      io
    end

  private

    def io
      @io ||= backend.open(id)
    end
  end
end
