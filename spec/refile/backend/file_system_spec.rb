RSpec.describe Refile::Backend::FileSystem do
  let(:backend) { Refile::Backend::FileSystem.new(File.expand_path("tmp/store1", Dir.pwd), max_size: 100) }

  it_behaves_like :backend

  describe "#upload" do
    it "efficiently copies a file if it has a path" do
      path = File.expand_path("tmp/test.txt", Dir.pwd)
      File.write(path, "hello")

      uploadable = Refile::FileDouble.new("wrong")
      allow(uploadable).to receive(:path).and_return(path)

      file = backend.upload(uploadable)

      expect(backend.get(file.id).read).to eq("hello")
    end

    it "ignores path if it doesn't exist" do
      path = File.expand_path("tmp/doesnotexist.txt", Dir.pwd)

      uploadable = Refile::FileDouble.new("yes")
      allow(uploadable).to receive(:path).and_return(path)

      file = backend.upload(uploadable)

      expect(backend.get(file.id).read).to eq("yes")
    end
  end
end
