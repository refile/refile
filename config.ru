$LOAD_PATH.unshift(File.expand_path("spec", File.dirname(__FILE__)))

require "pmacs_refile/test_app"

PmacsRefile::TestApp.config.action_dispatch.show_exceptions = true
PmacsRefile.app_host = "//localhost:9292"

run PmacsRefile::TestApp
