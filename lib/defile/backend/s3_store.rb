require "aws-sdk"

module Defile
  module Backend
    class S3
      def initialize(access_key_id:, secret_access_key:,bucket:, hasher: Defile::RandomHasher.new)
        @s3 = AWS::S3.new(access_key_id: access_key_id, secret_access_key: secret_access_key)
        @bucket_name = bucket
        @hasher = hasher
      end

      def cache(uploadable)
        Defile.verify_uploadable(uploadable)

        id = @hasher.hash(uploadable)

        bucket.objects[id].write(uploadable.to_io, content_length: uploadable.size)

        Defile::File.new(self, id)
      end

      def store(uploadable)
        Defile.verify_uploadable(uploadable)

        id = @hasher.hash(uploadable)

        bucket.objects[id].write(uploadable.to_io, content_length: uploadable.size)

        Defile::File.new(self, id)
      end

      def retrieve(id)
        Defile::File.new(self, id)
      end

      def delete(id)
      end

      def open(id)
      end

      def read(id)
        bucket.objects[id].read
      end

      def size(id)
        bucket.objects[id].content_length
      end

      def exists?(id)
        bucket.objects[id].exists?
      end

      def clear_cache!(older_than = nil)
      end

    private

      def bucket
        @bucket ||= @s3.buckets[@bucket_name]
      end
    end
  end
end
