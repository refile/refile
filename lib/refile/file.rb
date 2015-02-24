module Refile
  class File
    # @return [Backend] the backend the file is stored in
    attr_reader :backend

    # @return [String] the id of the file
    attr_reader :id

    # @api private
    def initialize(backend, id)
      @backend = backend
      @id = id
    end

    # Reads from the file.
    #
    # @see http://www.ruby-doc.org/core-2.2.0/IO.html#method-i-read
    #
    # @return [String] The contents of the read chunk
    def read(*args)
      io.read(*args)
    end

    # Returns whether there is more data to read. Returns true if the end of
    # the data has been reached.
    #
    # @return [Boolean]
    def eof?
      io.eof?
    end

    # Close the file object and release its file descriptor.
    #
    # @return [void]
    def close
      io.close
    end

    # @return [Integer] the size of the file in bytes
    def size
      backend.size(id)
    end

    # @return [String] the reported content type of file
    def type
      backend.type(id)
    end

    # Remove the file from the backend.
    #
    # @return [void]
    def delete
      backend.delete(id)
    end

    # @return [Boolean] whether the file exists in the backend
    def exists?
      backend.exists?(id)
    end

    # @return [IO] an IO object which contains the contents of the file
    def to_io
      io
    end

    # Downloads the file to a Tempfile on disk and returns this tempfile.
    #
    # @example
    #   file = backend.upload(StringIO.new("hello"))
    #   tempfile = file.download
    #   File.read(tempfile.path) # => "hello"
    #
    # @return [Tempfile] a tempfile with the file's content
    def download
      return io if io.is_a?(Tempfile)

      Tempfile.new(id, binmode: true).tap do |tempfile|
        IO.copy_stream(io, tempfile)
      end
    end

  private

    def io
      @io ||= backend.open(id)
    end
  end
end
