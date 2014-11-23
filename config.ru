$LOAD_PATH.unshift(File.expand_path("spec", File.dirname(__FILE__)))

require "defile/test_app"

Defile::TestApp.config.action_dispatch.show_exceptions = true
Defile.host = "//localhost:9292"

run Defile::TestApp
