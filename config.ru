$LOAD_PATH.unshift(File.expand_path("spec", File.dirname(__FILE__)))

require "defile/test_app"

Defile::TestApp.config.action_dispatch.show_exceptions = true

run Defile::TestApp
