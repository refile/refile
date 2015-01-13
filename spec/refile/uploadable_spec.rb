RSpec.describe Refile::Uploadable do
  let(:io) { double(size: 444, read: nil, eof?: true, close: nil) }

  describe "#initialize" do
    it "works if argument conforms to required API" do
      Refile::Uploadable.new(double(size: 444, read: nil, eof?: true, close: nil))
    end

    it "raises ArgumentError if argument does not respond to `size`" do
      expect { Refile::Uploadable.new(double(read: nil, eof?: true, close: nil)) }
        .to raise_error(ArgumentError)
    end

    it "raises ArgumentError if argument does not respond to `read`" do
      expect { Refile::Uploadable.new(double(size: 444, eof?: true, close: nil)) }
        .to raise_error(ArgumentError)
    end

    it "raises ArgumentError if argument does not respond to `eof?`" do
      expect { Refile::Uploadable.new(double(size: 444, read: true, close: nil)) }
        .to raise_error(ArgumentError)
    end

    it "raises ArgumentError if argument does not respond to `close`" do
      expect { Refile::Uploadable.new(double(size: 444, read: true, eof?: true)) }
        .to raise_error(ArgumentError)
    end
  end

  describe "#filename" do
    it "extracts filename from original_filename" do
      allow(io).to receive(:original_filename).and_return("baz.png")
      file = Refile::Uploadable.new(io)
      expect(file.filename).to eq("baz.png")
    end

    it "extracts filename from path" do
      allow(io).to receive(:path).and_return("/foo/bar/baz.png")
      file = Refile::Uploadable.new(io)
      expect(file.filename).to eq("baz.png")
    end

    it "returns nil if it can't determine filename" do
      file = Refile::Uploadable.new(io)
      expect(file.filename).to be_nil
    end
  end

  describe "#content_type" do
    it "extracts content type" do
      allow(io).to receive(:content_type).and_return("image/jpeg")
      file = Refile::Uploadable.new(io)
      expect(file.content_type).to eq("image/jpeg")
    end

    it "extracts content type from extension" do
      allow(io).to receive(:path).and_return("test.png")
      file = Refile::Uploadable.new(io)
      expect(file.content_type).to eq("image/png")
    end

    it "returns nil if it can't determine content type" do
      file = Refile::Uploadable.new(io)
      expect(file.content_type).to be_nil
    end

    it "returns nil if it has an unknown content type" do
      allow(io).to receive(:path).and_return("foo.blah")
      file = Refile::Uploadable.new(io)
      expect(file.content_type).to be_nil
    end
  end
end
