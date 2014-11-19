module Defile
  def self.verify_uploadable(uploadable)
    [:size, :to_io].each do |m|
      raise ArgumentError, "#{uploadable} does not respond to `#{m}` cannot upload" unless uploadable.respond_to?(m)
    end
    true
  end

  require "defile/version"
  require "defile/random_hasher"
  require "defile/file"
  require "defile/store"
  require "defile/store/file_store"
end
