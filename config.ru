$LOAD_PATH.unshift(File.expand_path("spec", File.dirname(__FILE__)))

require "refile/test_app"

Refile::TestApp.config.action_dispatch.show_exceptions = true
Refile.app_host = "//localhost:9292"

run Refile::TestApp
