module Refile
  # A file hasher which ignores the file contents and always returns a random string.
  class RandomHasher
    # Generate a random string
    #
    # @return [String]
    def hash(_uploadable = nil)
      SecureRandom.hex(30)
    end
  end
end
