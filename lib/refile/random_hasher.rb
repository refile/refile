# A file hasher which ignores the file contents and always returns a random string.
class Refile::RandomHasher

  # Generate a random string
  #
  # @return [String]
  def hash(uploadable=nil)
    SecureRandom.hex(30)
  end
end
