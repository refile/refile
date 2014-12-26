module Refile
  module Backend
    class FileSystem
      attr_reader :directory, :max_size

      def initialize(directory, max_size: nil, hasher: Refile::RandomHasher.new)
        @hasher = hasher
        @directory = directory
        @max_size = max_size

        FileUtils.mkdir_p(@directory)
      end

      def upload(uploadable)
        Refile.verify_uploadable(uploadable, @max_size)

        id = @hasher.hash(uploadable)
        IO.copy_stream(uploadable, path(id))

        Refile::File.new(self, id)
      end

      def get(id)
        Refile::File.new(self, id)
      end

      def delete(id)
        FileUtils.rm(path(id)) if exists?(id)
      end

      def open(id)
        ::File.open(path(id), "rb")
      end

      def read(id)
        ::File.read(path(id)) if exists?(id)
      end

      def size(id)
        ::File.size(path(id)) if exists?(id)
      end

      def exists?(id)
        ::File.exist?(path(id))
      end

      def clear!(confirm = nil)
        raise Refile::Confirm unless confirm == :confirm
        FileUtils.rm_rf(@directory)
        FileUtils.mkdir_p(@directory)
      end

      def path(id)
        ::File.join(@directory, id)
      end
    end
  end
end
