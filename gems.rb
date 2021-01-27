# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem "webmock", ">= 3.5.1"
gem "rspec", ">= 3.0"
gem "rspec-rails", ">= 3.3"
gem "jquery-rails"
gem "capybara"
gem "aws-sdk-s3"
gem "rack-test", ">= 0.6.2"
gem "rails", ">= 5.2"
gem "sqlite3", ">= 1.3.6",                         platforms: [:ruby]
gem "activerecord-jdbcsqlite3-adapter", ">= 52.1", platforms: [:jruby]
gem "poltergeist"
gem "yard"
gem "rubocop", ">= 0.49.0"
gem "puma"
gem "mini_magick"
gem "simple_form"
gem "i18n", ">= 1.2.0"
gem "mime-types"
gem "sinatra"
