RSpec.describe Defile::Store::FileStore do
  let(:store) { Defile::Store::FileStore.new(File.expand_path("tmp/store1", Dir.pwd)) }

  it_behaves_like :store

  it "efficiently copies a file" do

  end
end
