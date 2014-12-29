module Refile
  # A type represents an alias for one or multiple content types.
  # By adding types, you could simplify this:
  #
  #     attachment :document, content_type: %w[text/plain application/pdf]
  #
  # To this:
  #
  #     attachment :document, type: :document
  #
  # Simply define a new type like this:
  #
  #     Refile.types[:document] = Refile::Type.new(:document,
  #       content_type: %w[text/plain application/pdf]
  #     )
  #
  class Type
    # @return [String, Array<String>] The type's content types
    attr_accessor :content_type

    # @param [Symbol] name                            the name of the type
    # @param [String, Array<String>] content_type     content types which are valid for this type
    def initialize(name, content_type: nil)
      @name = name
      @content_type = content_type
    end
  end
end
