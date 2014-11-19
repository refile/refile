class Defile::RandomHasher
  def hash(uploadable)
    SecureRandom.hex(30)
  end
end
