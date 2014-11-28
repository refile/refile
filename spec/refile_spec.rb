require "refile"

RSpec.describe Refile do
  let(:io) { StringIO.new("hello") }

  describe ".verify_uploadable" do
    it "works if it conforms to required API" do
      expect(Refile.verify_uploadable(double(size: 444, read: io, eof?: true, close: nil), nil)).to be_truthy
    end

    it "raises ArgumentError if argument does not respond to `size`" do
      expect { Refile.verify_uploadable(double(read: io, eof?: true, close: nil), nil) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError if argument does not respond to `read`" do
      expect { Refile.verify_uploadable(double(size: 444, eof?: true, close: nil), nil) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError if argument does not respond to `eof?`" do
      expect { Refile.verify_uploadable(double(size: 444, read: true, close: nil), nil) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError if argument does not respond to `close`" do
      expect { Refile.verify_uploadable(double(size: 444, read: true, eof?: true), nil) }.to raise_error(ArgumentError)
    end

    it "returns true if size is respeced" do
      expect(Refile.verify_uploadable(Refile::FileDouble.new("hello"), 8)).to be_truthy
    end

    it "raises Refile::Invalid if size is exceeded" do
      expect { Refile.verify_uploadable(Refile::FileDouble.new("hello world"), 8) }.to raise_error(Refile::Invalid)
    end
  end
end
