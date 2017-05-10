require "./lib/refile/version"

Gem::Specification.new do |spec|
  spec.name          = "pmacs_refile"
  spec.version       = PmacsRefile::VERSION
  spec.authors       = ["Jonas Nicklas"]
  spec.email         = ["jonas.nicklas@gmail.com"]
  spec.summary       = "Simple and powerful file upload library"
  spec.homepage      = "https://github.com/refile/refile"
  spec.license       = "MIT"

  spec.files         = `git ls-files lib spec app config Readme.md`.split($/).reject { |f| f.include?("test_app") }
  spec.require_paths = %w[lib spec] # spec is used by backend gems to run their tests

  spec.required_ruby_version = ">= 2.1.0"

  spec.add_dependency "rest-client", "~> 1.8"
  spec.add_dependency "sinatra", "2.0.0.rc1"
  spec.add_dependency "mime-types"
end
