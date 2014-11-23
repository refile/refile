require 'action_controller/railtie'
require 'defile'

module Defile
  class TestApp < Rails::Application
    config.secret_token = '6805012ab1750f461ef3c531bdce84c0'
    config.session_store :cookie_store, :key => '_defile_session'
    config.active_support.deprecation = :log
    config.eager_load = false
    config.show_exceptions = true
    config.root = ::File.expand_path("test_app", ::File.dirname(__FILE__))
    config.database_configuration = {
    }
  end

  Rails.backtrace_cleaner.remove_silencers!
  TestApp.initialize!
end
