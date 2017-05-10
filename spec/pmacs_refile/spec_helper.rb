ENV["RACK_ENV"] = "test"

require "pmacs_refile"
require "pmacs_refile/backend_examples"
require "webmock/rspec"
require "pmacs_refile/file_double"

tmp_path = Dir.mktmpdir

WebMock.disable_net_connect!(allow_localhost: true)

at_exit do
  FileUtils.remove_entry_secure(tmp_path)
end

PmacsRefile.store = PmacsRefile::Backend::FileSystem.new(File.expand_path("default_store", tmp_path))
PmacsRefile.cache = PmacsRefile::Backend::FileSystem.new(File.expand_path("default_cache", tmp_path))

class FakePresignBackend < PmacsRefile::Backend::FileSystem
  def presign
    id = PmacsRefile::RandomHasher.new.hash
    PmacsRefile::Signature.new(as: "file", id: id, url: "/presigned/posts/upload", fields: { id: id, token: "xyz123" })
  end
end

PmacsRefile.secret_key = "144c82de680afe5e8e91fc7cf13c22b2f8d2d4b1a4a0e92531979b12e2fa8b6dd6239c65be28517f27f442bfba11572a8bef80acf44a11f465ba85dde85488d5"

PmacsRefile.backends["limited_cache"] = FakePresignBackend.new(File.expand_path("default_cache", tmp_path), max_size: 100)

PmacsRefile.allow_uploads_to = %w[cache limited_cache]

PmacsRefile.allow_origin = "*"

PmacsRefile.app_host = "http://localhost:56120"

PmacsRefile.processor(:reverse) do |file|
  StringIO.new(file.read.reverse)
end

PmacsRefile.processor(:upcase, proc { |file| StringIO.new(file.read.upcase) })

PmacsRefile.logger = Logger.new(nil)

PmacsRefile.processor(:concat) do |file, *words|
  tempfile = Tempfile.new("concat")
  tempfile.write(file.read)
  words.each do |word|
    tempfile.write(word)
  end
  tempfile.close
  File.open(tempfile.path, "r")
end

PmacsRefile.processor(:convert_case) do |file, options = {}|
  case options[:format]
    when "up" then StringIO.new(file.read.upcase)
    when "down" then StringIO.new(file.read.downcase)
    else file
  end
end

module PathHelper
  def path(filename)
    File.expand_path(File.join("fixtures", filename), File.dirname(__FILE__))
  end
end

RSpec.configure do |config|
  config.include PathHelper
end

RSpec::Expectations.configuration.warn_about_potential_false_positives = false
