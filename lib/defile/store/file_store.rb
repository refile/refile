require "fileutils"

class Defile::Store::FileStore < Defile::Store
  def initialize(directory, hasher: Defile::RandomHasher.new)
    @directory = directory
    @hasher = hasher
    @cache_directory = File.join(directory, "cache")
    @store_directory = File.join(directory, "store")
    FileUtils.mkdir_p(@cache_directory)
    FileUtils.mkdir_p(@store_directory)
  end

  def cache(uploadable)
    Defile.verify_uploadable(uploadable)

    id = @hasher.hash(uploadable)

    File.write(cache_path(id), uploadable.read)

    Defile::File.new(self, id)
  end

  def store(uploadable)
    Defile.verify_uploadable(uploadable)

    id = @hasher.hash(uploadable)

    File.write(store_path(id), uploadable.read)

    Defile::File.new(self, id)
  end

  def retrieve(id)
    Defile::File.new(self, id)
  end

  def delete(id)
  end

  def read(id)
    path = get_path_from_id(id)
    File.read(path) if path
  end

  def size(id)
    path = get_path_from_id(id)
    File.size(path) if path
  end

  def exists?(id)
    !!get_path_from_id(id)
  end

  def clear_cache!(older_than = nil)
    if older_than
    else
      FileUtils.rm_rf(@cache_directory)
      FileUtils.mkdir_p(@cache_directory)
    end
  end

private

  def get_path_from_id(id)
    if File.exist?(store_path(id))
      store_path(id)
    elsif File.exist?(cache_path(id))
      cache_path(id)
    end
  end

  def cache_path(id)
    File.join(@cache_directory, id)
  end

  def store_path(id)
    File.join(@store_directory, id)
  end
end
