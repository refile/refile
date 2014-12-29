require "rails/all"

require "refile"
require "refile/rails"
require "jquery/rails"

module Refile
  class TestApp < Rails::Application
    config.secret_token = "6805012ab1750f461ef3c531bdce84c0"
    config.session_store :cookie_store, key: "_refile_session"
    config.active_support.deprecation = :log
    config.eager_load = false
    config.action_dispatch.show_exceptions = false
    config.consider_all_requests_local = true
    config.root = ::File.expand_path("test_app", ::File.dirname(__FILE__))
  end

  Rails.backtrace_cleaner.remove_silencers!
  TestApp.initialize!
end

require "rspec"
require "rspec/rails"
require "capybara/rails"
require "capybara/rspec"
require "refile/spec_helper"
require "refile/active_record_helper"

if ENV["SAUCE_BROWSER"]
  Capybara.register_driver :selenium do |app|
    url = "http://#{ENV["SAUCE_USERNAME"]}:#{ENV["SAUCE_ACCESS_KEY"]}@localhost:4445/wd/hub"
    capabilities = { browserName: ENV["SAUCE_BROWSER"], version: ENV["SAUCE_VERSION"] }
    driver = Capybara::Selenium::Driver.new(app, browser: :remote, url: url, desired_capabilities: capabilities)
    driver.browser.file_detector = ->(args) { args.first if File.exist?(args.first) }
    driver
  end
end

Capybara.configure do |config|
  config.server_port = 56_120
end

Refile.allow_origin = "*"
Refile.host = "//localhost:56120"

module TestAppHelpers
  def download_link(text)
    url = find_link(text)[:href]
    if Capybara.current_driver == :rack_test
      using_session :other do
        visit(url)
        page.source.chomp
      end
    else
      Net::HTTP.get_response(URI(url)).body.chomp
    end
  end
end

RSpec.configure do |config|
  config.include TestAppHelpers, type: :feature
  config.before(:all) do
    Refile.logger = Rails.logger
  end
end
