require "aws-sdk"

module Defile
  module Backend
    class S3
      # Emulates an IO-object like interface on top of S3Object#read. To avoid
      # memory allocations and unnecessary complexity, this treats the `length`
      # parameter to read as a boolean flag instead. If given, it will read the
      # file in chunks of undetermined size, if not given it will read the
      # entire file.
      class Reader
        def initialize(object)
          @object = object
          @closed = false
        end

        def read(length = nil, buffer = nil)
          result = if length
            raise "closed" if @closed

            unless eof? # sets @peek
              @peek
            end
          else
            @object.read
          end
          buffer.replace(result) if buffer and result
          result
        ensure
          @peek = nil
        end

        def eof?
          @peek ||= enumerator.next
          false
        rescue StopIteration
          true
        end

        def size
          @object.content_length
        end

        def close
          @closed = true
        end

      private

        def enumerator
          @enumerator ||= @object.to_enum(:read)
        end
      end

      attr_reader :access_key_id

      def initialize(type = :store, access_key_id:, secret_access_key:,bucket:, hasher: Defile::RandomHasher.new)
        @type = type
        @access_key_id = access_key_id
        @secret_access_key = secret_access_key
        @s3 = AWS::S3.new(access_key_id: access_key_id, secret_access_key: secret_access_key)
        @bucket_name = bucket
        @hasher = hasher
      end

      def upload(uploadable)
        Defile.verify_uploadable(uploadable)

        id = @hasher.hash(uploadable)

        object(id).write(uploadable, content_length: uploadable.size)

        Defile::File.new(self, id)
      end

      def get(id)
        Defile::File.new(self, id)
      end

      def delete(id)
        object(id).delete
      end

      def open(id)
        Reader.new(object(id))
      end

      def read(id)
        object(id).read
      rescue AWS::S3::Errors::NoSuchKey
        nil
      end

      def size(id)
        object(id).content_length
      rescue AWS::S3::Errors::NoSuchKey
        nil
      end

      def exists?(id)
        object(id).exists?
      end

      def clear!(older_than = nil)
        raise "for safety reasons, refusing to clear store" if @type == :store
        @bucket.objects.with_prefix(@type).delete_all
      end

      def to_store
        self.class.new(:store, access_key_id: @access_key_id, secret_access_key: @secret_access_key, hasher: @hasher, bucket: @bucket_name)
      end

      def to_cache
        self.class.new(:cache, access_key_id: @access_key_id, secret_access_key: @secret_access_key, hasher: @hasher, bucket: @bucket_name)
      end

      def object(id)
        bucket.objects[[@type, id].join("/")]
      end

    private

      def bucket
        @bucket ||= @s3.buckets[@bucket_name]
      end
    end
  end
end
