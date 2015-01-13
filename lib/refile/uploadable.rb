require "forwardable"
require "mime/types"

module Refile
  class Uploadable
    extend Forwardable

    IO_METHODS = [:size, :read, :eof?, :close]

    def self.validate!(io)
      IO_METHODS.each do |m|
        unless io.respond_to?(m)
          raise ArgumentError, "does not respond to `#{m}`."
        end
      end
    end

    # @param io [#read, #eof?, #close, #size]
    #
    # @api private
    def initialize(io)
      self.class.validate!(io)
      @io = io
    end

    delegate IO_METHODS => :io

    # Extracts the filename from the underlying IO. If the filename cannot be
    # determined, this method will return `nil`.
    #
    # @return [String, nil]     The extracted filename
    def filename
      return io.original_filename     if io.respond_to?(:original_filename)
      return ::File.basename(io.path) if io.respond_to?(:path)
    end

    # Extracts the content type from underlying IO. If the content type cannot
    # be determined, this method will return `nil`.
    #
    # @return [String, nil]     The extracted content type
    def content_type
      return io.content_type if io.respond_to?(:content_type)

      if filename
        content_type = MIME::Types.of(filename).first
        content_type.to_s if content_type
      end
    end

  private

    attr_reader :io
  end
end
