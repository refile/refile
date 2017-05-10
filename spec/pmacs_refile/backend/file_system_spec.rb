RSpec.describe Refile::Backend::FileSystem do
  let(:backend) { Refile::Backend::FileSystem.new(File.expand_path("tmp/store1", Dir.pwd), max_size: 100) }

  it_behaves_like :backend
end
