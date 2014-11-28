module Refile
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

    def download
      tempfile = Tempfile.new(id)
      tempfile.binmode
      each do |chunk|
        tempfile.write(chunk)
      end
      close
      tempfile.close
      tempfile
    end

    def each
      if block_given?
        until eof?
          yield(read(Refile.read_chunk_size))
        end
      else
        to_enum
      end
    end

  private

    def io
      @io ||= backend.open(id)
    end
  end
end
