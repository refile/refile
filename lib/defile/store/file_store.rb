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

    copy(uploadable, cache_path(id))

    Defile::File.new(self, id)
  end

  def store(uploadable)
    Defile.verify_uploadable(uploadable)

    id = @hasher.hash(uploadable)

    copy(uploadable, store_path(id))

    Defile::File.new(self, id)
  end

  def retrieve(id)
    Defile::File.new(self, id)
  end

  def delete(id)
    path = get_path_from_id(id)
    FileUtils.rm(path) if path
  end

  def open(id)
    path = get_path_from_id(id)
    if path
      if block_given?
        File.open(path, "r") { |file| yield(file) }
      else
        File.open(path, "r")
      end
    end
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

  def copy(uploadable, destination)
    if uploadable.respond_to?(:path)
      FileUtils.cp(uploadable.path, destination)
    else
      File.open(destination, "wb") do |write|
        read = uploadable.to_io
        read.each("", Defile.read_chunk_size) do |chunk|
          write.write(chunk)
        end
        read.close
      end
    end
  end

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
