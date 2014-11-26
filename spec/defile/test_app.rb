require "rails/all"

require "defile"
require "defile/rails"
require "jquery/rails"

module Defile
  class TestApp < Rails::Application
    config.secret_token = '6805012ab1750f461ef3c531bdce84c0'
    config.session_store :cookie_store, :key => '_defile_session'
    config.active_support.deprecation = :log
    config.eager_load = false
    config.action_dispatch.show_exceptions = false
    config.consider_all_requests_local = true
    config.root = ::File.expand_path("test_app", ::File.dirname(__FILE__))
  end

  Rails.backtrace_cleaner.remove_silencers!
  TestApp.initialize!
end

class TestMigration < ActiveRecord::Migration
  def self.up
    create_table :posts, :force => true do |t|
      t.column :title, :string
      t.column :image_id, :string
      t.column :document_id, :string
    end
  end
end

quietly do
  TestMigration.up
end

require "rspec"
require "rspec/rails"
require "capybara/rails"
require "capybara/rspec"
require "defile/spec_helper"

Capybara.configure do |config|
  config.server_port = 56120
end

Defile.host = "//127.0.0.1:56120"
