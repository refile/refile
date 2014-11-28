$LOAD_PATH.unshift(File.expand_path("spec", File.dirname(__FILE__)))

require "bundler/gem_tasks"
require "refile/test_app"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

Rails.application.load_tasks
