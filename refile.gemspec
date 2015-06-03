# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "refile/version"

Gem::Specification.new do |spec|
  spec.name          = "refile"
  spec.version       = Refile::VERSION
  spec.authors       = ["Jonas Nicklas"]
  spec.email         = ["jonas.nicklas@gmail.com"]
  spec.summary       = "Simple and powerful file upload library"
  spec.homepage      = "https://github.com/refile/refile"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w[lib spec]

  spec.required_ruby_version = ">= 2.1.0"

  spec.add_dependency "rest-client", "~> 1.8"
  spec.add_dependency "sinatra", "~> 1.4.5"
  spec.add_dependency "mime-types"
end
