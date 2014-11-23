require "defile/spec_helper"
require "rails/all"
require "defile/test_app"
require "rspec/rails"
require "capybara/rails"
require "capybara/rspec"

Capybara.configure do |config|
  config.server_port = 56120
end

