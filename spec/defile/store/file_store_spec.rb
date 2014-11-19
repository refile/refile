require "defile"
require "defile/store_examples"

RSpec.describe Defile::Store::FileStore do
  let(:store) { Defile::Store::FileStore.new(File.expand_path("tmp/store1", Dir.pwd)) }

  it_behaves_like :store
end
