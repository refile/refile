$LOAD_PATH.unshift(File.expand_path("spec", File.dirname(__FILE__)))

require "bundler/gem_tasks"
require "refile/test_app"
require "rspec/core/rake_task"
require "yard"

YARD::Rake::YardocTask.new do |t|
  t.files = ["README.md", "lib/**/*.rb"]
end

RSpec::Core::RakeTask.new(:spec)

task default: :spec

Rails.application.load_tasks
