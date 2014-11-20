module Defile
  module Backend
    class FileSystem
      def initialize(type = :store, directory, hasher: Defile::RandomHasher.new)
        @type = type
        @directory = directory
        @hasher = hasher
        @directory = directory
        @full_directory = ::File.join(directory, @type.to_s)

        FileUtils.mkdir_p(@full_directory)
      end

      def upload(uploadable)
        Defile.verify_uploadable(uploadable)

        id = @hasher.hash(uploadable)

        if uploadable.respond_to?(:path)
          FileUtils.cp(uploadable.path, path(id))
        else
          ::File.open(path(id), "wb") do |file|
            Defile.stream(uploadable).each do |chunk|
              file.write(chunk)
            end
          end
        end

        Defile::File.new(self, id)
      end

      def get(id)
        Defile::File.new(self, id)
      end

      def delete(id)
        FileUtils.rm(path(id)) if exists?(id)
      end

      def stream(id)
        Defile::Stream.new(::File.open(path(id), "r")).each
      end

      def read(id)
        ::File.read(path(id)) if exists?(id)
      end

      def size(id)
        ::File.size(path(id)) if exists?(id)
      end

      def exists?(id)
        ::File.exists?(path(id))
      end

      def clear!(older_than = nil)
        raise "for safety reasons, refusing to clear store" if @type == :store
        if older_than
        else
          FileUtils.rm_rf(@full_directory)
          FileUtils.mkdir_p(@full_directory)
        end
      end

      def path(id)
        ::File.join(@full_directory, id)
      end

      def to_store
        self.class.new(:store, @directory, hasher: @hasher)
      end

      def to_cache
        self.class.new(:cache, @directory, hasher: @hasher)
      end
    end
  end
end
