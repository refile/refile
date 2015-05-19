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
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = %w[lib spec]

  spec.required_ruby_version = ">= 2.1.0"

  spec.add_dependency "rest-client", "~> 1.8"
  spec.add_dependency "sinatra", "~> 1.4.5"
  spec.add_dependency "mime-types"

  spec.add_development_dependency "webmock", "~> 1.20.4"
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-rails", "~> 3.0"
  spec.add_development_dependency "jquery-rails"
  spec.add_development_dependency "capybara"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "aws-sdk"
  spec.add_development_dependency "rack-test", "~> 0.6.2"
  spec.add_development_dependency "rails", "~> 4.1.8"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "selenium-webdriver"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "redcarpet"
end
