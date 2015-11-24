module Refile
  class FileDouble
    attr_reader :original_filename, :content_type
    def initialize(data, name = nil, content_type: nil)
      @io = StringIO.new(data)
      @original_filename = name
      @content_type = content_type
    end

    extend Forwardable
    def_delegators :@io, :read, :rewind, :size, :eof?, :close
  end
end
