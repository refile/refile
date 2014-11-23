$LOAD_PATH.unshift(File.expand_path("spec", File.dirname(__FILE__)))

require "defile/test_app"

run Defile::TestApp
