module Refile
  class Signature
    attr_reader :as, :id, :url, :fields

    def initialize(as:, id:, url:, fields:)
      @as = as
      @id = id
      @url = url
      @fields = fields
    end

    def as_json(*)
      { as: @as, id: @id, url: @url, fields: @fields }
    end
  end
end
