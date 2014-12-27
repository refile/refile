require "aws-sdk"
require "open-uri"

module Refile
  module Backend
    # A refile backend which stores files in Amazon S3
    class S3
      attr_reader :access_key_id, :max_size

      def initialize(access_key_id:, secret_access_key:, bucket:, max_size: nil, prefix: nil, hasher: Refile::RandomHasher.new, **s3_options)
        @access_key_id = access_key_id
        @secret_access_key = secret_access_key
        @s3_options = { access_key_id: access_key_id, secret_access_key: secret_access_key }.merge s3_options
        @s3 = AWS::S3.new @s3_options
        @bucket_name = bucket
        @bucket = @s3.buckets[@bucket_name]
        @hasher = hasher
        @prefix = prefix
        @max_size = max_size
      end

      def upload(uploadable)
        Refile.verify_uploadable(uploadable, @max_size)

        id = @hasher.hash(uploadable)

        if uploadable.is_a?(Refile::File) and uploadable.backend.is_a?(S3) and uploadable.backend.access_key_id == access_key_id
          uploadable.backend.object(uploadable.id).copy_to(object(id))
        else
          object(id).write(uploadable, content_length: uploadable.size)
        end

        Refile::File.new(self, id)
      end

      def get(id)
        Refile::File.new(self, id)
      end

      def delete(id)
        object(id).delete
      end

      def open(id)
        Kernel.open(object(id).url_for(:read))
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
        raise Refile::Confirm unless confirm == :confirm
        @bucket.objects.with_prefix(@prefix).delete_all
      end

      def presign
        id = RandomHasher.new.hash
        signature = @bucket.presigned_post(key: [*@prefix, id].join("/"))
        signature.where(content_length: @max_size) if @max_size
        Signature.new(as: "file", id: id, url: signature.url.to_s, fields: signature.fields)
      end

      def object(id)
        @bucket.objects[[*@prefix, id].join("/")]
      end
    end
  end
end
