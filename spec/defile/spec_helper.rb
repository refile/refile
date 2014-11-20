require "pry"
require "defile"
require "defile/backend_examples"

tmp_path = File.expand_path("tmp", Dir.pwd)

if File.exist?(tmp_path)
  raise "temporary path #{tmp_path} already exists, refusing to run tests"
else
  RSpec.configure do |config|
    config.after :suite do
      FileUtils.rm_rf(tmp_path)
    end
  end
end

Defile.store = Defile::Backend::FileSystem.new(File.expand_path("default_store", tmp_path))
Defile.cache = Defile::Backend::FileSystem.new(File.expand_path("default_cache", tmp_path))

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
