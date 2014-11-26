# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'defile/version'

Gem::Specification.new do |spec|
  spec.name          = "defile"
  spec.version       = Defile::VERSION
  spec.authors       = ["Jonas Nicklas"]
  spec.email         = ["jonas.nicklas@gmail.com"]
  spec.summary       = %q{Simple and powerful file upload library}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.1.0"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-rails", "~> 3.0"
  spec.add_development_dependency "jquery-rails"
  spec.add_development_dependency "capybara"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "aws-sdk"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rails"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "selenium-webdriver"
end
