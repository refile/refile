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

      def initialize(access_key_id:, secret_access_key:, bucket:, prefix: nil, hasher: Defile::RandomHasher.new)
        @access_key_id = access_key_id
        @secret_access_key = secret_access_key
        @s3 = AWS::S3.new(access_key_id: access_key_id, secret_access_key: secret_access_key)
        @bucket_name = bucket
        @bucket = @s3.buckets[@bucket_name]
        @hasher = hasher
        @prefix = prefix
      end

      def upload(uploadable)
        Defile.verify_uploadable(uploadable)

        id = @hasher.hash(uploadable)

        if uploadable.is_a?(Defile::File) and uploadable.backend.is_a?(S3) and uploadable.backend.access_key_id == access_key_id
          uploadable.backend.object(uploadable.id).copy_to(object(id))
        else
          object(id).write(uploadable, content_length: uploadable.size)
        end

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

      def clear!(confirm = nil)
        raise ArgumentError, "are you sure? this will remove all files in the backend, call as `clear!(:confirm)` if you're sure you want to do this" unless confirm == :confirm
        @bucket.objects.with_prefix(@prefix).delete_all
      end

      def object(id)
        @bucket.objects[[*@prefix, id].join("/")]
      end
    end
  end
end
