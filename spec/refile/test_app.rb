require "pry"
require "yaml"
require "rails/all"

require "refile"
require "refile/rails"
require "jquery/rails"

module Refile
  class TestApp < Rails::Application
    config.middleware.delete "ActionDispatch::Cookies"
    config.middleware.delete "ActionDispatch::Session::CookieStore"
    config.middleware.delete "ActionDispatch::Flash"
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
require "capybara/poltergeist"

if ENV["SAUCE_BROWSER"]
  Capybara.register_driver :selenium do |app|
    url = "http://#{ENV["SAUCE_USERNAME"]}:#{ENV["SAUCE_ACCESS_KEY"]}@localhost:4445/wd/hub"
    capabilities = { browserName: ENV["SAUCE_BROWSER"], version: ENV["SAUCE_VERSION"] }
    driver = Capybara::Selenium::Driver.new(app, browser: :remote, url: url, desired_capabilities: capabilities)
    driver.browser.file_detector = ->(args) { args.first if File.exist?(args.first) }
    driver
  end
end

Capybara.javascript_driver = :poltergeist

Capybara.configure do |config|
  config.server_port = 56_120
end

module TestAppHelpers
  def download_link(text)
    url = find_link(text)[:href]
    if Capybara.current_driver == :rack_test
      using_session :other do
        visit(url)
        page.source.chomp
      end
    else
      uri = URI(url)
      uri.scheme ||= "http"
      Net::HTTP.get_response(URI(uri.to_s)).body.chomp
    end
  end
end

RSpec.configure do |config|
  config.include TestAppHelpers, type: :feature
  config.before(:all) do
    Refile.logger = Rails.logger
  end
end
