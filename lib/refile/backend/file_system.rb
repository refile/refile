module Refile
  module Backend
    # A backend which stores uploaded files in the local filesystem
    #
    # @example
    #   backend = Refile::Backend::FileSystem.new("some/path")
    #   file = backend.upload(StringIO.new("hello"))
    #   backend.read(file.id) # => "hello"
    class FileSystem
      extend Refile::BackendMacros

      # @return [String] the directory where files are stored
      attr_reader :directory

      # @return [String] the maximum size of files stored in this backend
      attr_reader :max_size

      # Creates the given directory if it doesn't exist.
      #
      # @param [String] directory         The path to a directory where files should be stored
      # @param [Integer, nil] max_size    The maximum size of an uploaded file
      # @param [#hash] hasher             A hasher which is used to generate ids from files
      def initialize(directory, max_size: nil, hasher: Refile::RandomHasher.new)
        @hasher = hasher
        @directory = directory
        @max_size = max_size

        FileUtils.mkdir_p(@directory)
      end

      # Upload a file into this backend
      #
      # @param [IO] uploadable      An uploadable IO-like object.
      # @return [Refile::File]      The uploaded file
      verify_uploadable def upload(uploadable, id: nil)
        id ||= @hasher.hash(uploadable)
        IO.copy_stream(uploadable, path(id))

        Refile::File.new(self, id)
      end

      # Get a file from this backend.
      #
      # Note that this method will always return a {Refile::File} object, even
      # if a file with the given id does not exist in this backend. Use
      # {FileSystem#exists?} to check if the file actually exists.
      #
      # @param [Sring] id           The id of the file
      # @return [Refile::File]      The retrieved file
      verify_id def get(id)
        Refile::File.new(self, id)
      end

      # Delete a file from this backend
      #
      # @param [Sring] id           The id of the file
      # @return [void]
      verify_id def delete(id)
        FileUtils.rm(path(id)) if exists?(id)
      end

      # Return an IO object for the uploaded file which can be used to read its
      # content.
      #
      # @param [Sring] id           The id of the file
      # @return [IO]                An IO object containing the file contents
      verify_id def open(id)
        ::File.open(path(id), "rb")
      end

      # Return the entire contents of the uploaded file as a String.
      #
      # @param [Sring] id           The id of the file
      # @return [String]            The file's contents
      verify_id def read(id)
        ::File.read(path(id)) if exists?(id)
      end

      # Return the size in bytes of the uploaded file.
      #
      # @param [Sring] id           The id of the file
      # @return [Integer]           The file's size
      verify_id def size(id)
        ::File.size(path(id)) if exists?(id)
      end

      # Return whether the file with the given id exists in this backend.
      #
      # @param [Sring] id           The id of the file
      # @return [Boolean]
      verify_id def exists?(id)
        ::File.exist?(path(id))
      end

      # Remove all files in this backend. You must confirm the deletion by
      # passing the symbol `:confirm` as an argument to this method.
      #
      # @example
      #   backend.clear!(:confirm)
      # @raise [Refile::Confirm]     Unless the `:confirm` symbol has been passed.
      # @param [:confirm] confirm    Pass the symbol `:confirm` to confirm deletion.
      # @return [void]
      def clear!(confirm = nil)
        raise Refile::Confirm unless confirm == :confirm
        FileUtils.rm_rf(@directory)
        FileUtils.mkdir_p(@directory)
      end

      # Return the full path of the uploaded file with the given id.
      #
      # @param [Sring] id           The id of the file
      # @return [String]
      verify_id def path(id)
        ::File.join(@directory, id)
      end
    end
  end
end
