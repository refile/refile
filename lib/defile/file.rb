module Defile
  class File
    attr_reader :backend, :id

    def initialize(backend, id)
      @backend = backend
      @id = id
    end

    def read(*args)
      @peek || io.read(*args)
    ensure
      @peek = nil
    end

    def peek(limit = nil)
      @peek ||= read(limit)
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

    def each
      while @peek or not eof?
        yield(read(Defile.read_chunk_size))
      end
    end

  private

    def io
      @io ||= backend.open(id)
    end
  end
end
