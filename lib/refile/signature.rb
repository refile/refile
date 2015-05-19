module Refile
  # A signature summarizes an HTTP request a client can make to upload a file
  # to directly upload a file to a backend. This signature is usually generated
  # by a backend's `presign` method.
  class Signature
    # @return [String] the name of the field that the file will be uploaded as.
    attr_reader :as

    # @return [String] the id the file will receive once uploaded.
    attr_reader :id

    # @return [String] the url the file should be uploaded to.
    attr_reader :url

    # @return [String] additional fields to be sent alongside the file.
    attr_reader :fields

    # @api private
    def initialize(as:, id:, url:, fields:)
      @as = as
      @id = id
      @url = url
      @fields = fields
    end

    # @return [Hash{Symbol => Object}] an object suitable for serialization to JSON
    def as_json(*)
      { as: @as, id: @id, url: @url, fields: @fields }
    end

    # @return [String] the signature serialized as JSON
    def to_json(*)
      as_json.to_json
    end
  end
end
