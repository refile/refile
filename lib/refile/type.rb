module Refile
  class Type
    attr_accessor :content_type

    def initialize(name, content_type: nil)
      @name = name
      @content_type = content_type
    end
  end
end
