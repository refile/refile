RSpec.describe Defile::Backend::FileSystem do
  let(:backend) { Defile::Backend::FileSystem.new(File.expand_path("tmp/store1", Dir.pwd)) }

  it_behaves_like :backend

  describe "#cache" do
    it "efficiently copies a file if it has a path" do
      path = File.expand_path("tmp/test.txt", Dir.pwd)
      File.write(path, "hello")

      file = backend.cache(double(size: 1234, to_io: StringIO.new("wrong"), path: path))

      expect(backend.retrieve(file.id).read).to eq("hello")
    end
  end

  describe "#store" do
    it "efficiently copies a file if it has a path" do
      path = File.expand_path("tmp/test.txt", Dir.pwd)
      File.write(path, "hello")

      file = backend.store(double(size: 1234, to_io: StringIO.new("wrong"), path: path))

      expect(backend.retrieve(file.id).read).to eq("hello")
    end
  end
end
