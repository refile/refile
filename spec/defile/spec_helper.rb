require "pry"
require "defile"
require "defile/backend_examples"

tmp_path = Dir.mktmpdir

at_exit do
  FileUtils.remove_entry_secure(tmp_path)
end

Defile.store = Defile::Backend::FileSystem.new(File.expand_path("default_store", tmp_path))
Defile.cache = Defile::Backend::FileSystem.new(File.expand_path("default_cache", tmp_path))
Defile.backends["limited_cache"] = Defile::Backend::FileSystem.new(File.expand_path("default_cache", tmp_path), max_size: 100)

Defile.direct_upload = ["cache", "limited_cache"]

class Defile::FileDouble
  def initialize(data)
    @io = StringIO.new(data)
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

module PathHelper
  def path(filename)
    File.expand_path(File.join("fixtures", filename), File.dirname(__FILE__))
  end
end

RSpec.configure do |config|
  config.include PathHelper
end

