RSpec.describe PmacsRefile::Backend::FileSystem do
  let(:backend) { PmacsRefile::Backend::FileSystem.new(File.expand_path("tmp/store1", Dir.pwd), max_size: 100) }

  it_behaves_like :backend
end
