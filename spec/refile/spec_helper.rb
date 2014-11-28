require "pry"
require "refile"
require "refile/backend_examples"

tmp_path = Dir.mktmpdir

at_exit do
  FileUtils.remove_entry_secure(tmp_path)
end

Refile.store = Refile::Backend::FileSystem.new(File.expand_path("default_store", tmp_path))
Refile.cache = Refile::Backend::FileSystem.new(File.expand_path("default_cache", tmp_path))

class FakePresignBackend < Refile::Backend::FileSystem
  Signature = Struct.new(:as, :id, :url, :fields)

  def presign
    id = Refile::RandomHasher.new.hash
    Signature.new("file", id, "/presigned/posts/upload", { token: "xyz123", id: id })
  end
end

Refile.backends["limited_cache"] = FakePresignBackend.new(File.expand_path("default_cache", tmp_path), max_size: 100)

Refile.direct_upload = ["cache", "limited_cache"]

class Refile::FileDouble
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

