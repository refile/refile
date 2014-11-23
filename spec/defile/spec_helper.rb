require "pry"
require "defile"
require "defile/backend_examples"

tmp_path = Dir.mktmpdir

at_exit do
  FileUtils.remove_entry_secure(tmp_path)
end

Defile.store = Defile::Backend::FileSystem.new(File.expand_path("default_store", tmp_path))
Defile.cache = Defile::Backend::FileSystem.new(File.expand_path("default_cache", tmp_path))

class Defile::FileDouble
  def initialize(data, name=nil)
    @io = StringIO.new(data)
    if name
      singleton_class.send(:define_method, :original_filename) do
        name
      end
    end
  end

  def read(*args)
    @io.read(*args)
  end

  def size
    @io.size
  end

  def eof?
    @io.eof?
  end

  def close
    @io.close
  end
end
