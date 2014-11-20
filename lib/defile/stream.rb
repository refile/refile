module Defile
  class Stream
    def initialize(fd)
      @fd = fd
      @enumerator = @fd.each("", Defile.read_chunk_size)
    end

    def each
      if block_given?
        begin
          loop do
            yield(@enumerator.next)
          end
        ensure
          @fd.close
        end
      else
        to_enum
      end
    end
  end
end
