RSpec.describe Defile::Backend::FileSystem do
  def uploadable(data = "hello")
    double(size: data.length, to_io: StringIO.new(data))
  end

  let(:backend) { Defile::Backend::FileSystem.new(File.expand_path("tmp/store1", Dir.pwd)) }

  it_behaves_like :backend

  describe "#upload" do
    it "efficiently copies a file if it has a path" do
      path = File.expand_path("tmp/test.txt", Dir.pwd)
      File.write(path, "hello")

      file = backend.upload(double(size: 1234, to_io: StringIO.new("wrong"), path: path))

      expect(backend.get(file.id).read).to eq("hello")
    end
  end

  describe "#stream" do
    if defined?(ObjectSpace) # usually doesn't exist on JRuby
      it "doesn't leak file descriptors" do
        file = backend.upload(uploadable)

        before = ObjectSpace.each_object(File).reject { |f| f.closed? }

        expect(backend.stream(file.id).to_a.join).to eq("hello")

        after = ObjectSpace.each_object(File).reject { |f| f.closed? }

        expect(after).to eq(before)
      end
    end
  end
end
