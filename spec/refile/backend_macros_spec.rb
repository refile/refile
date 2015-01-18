RSpec.describe Refile::BackendMacros do
  let(:klass) do
    Class.new do
      extend Refile::BackendMacros

      attr_accessor :max_size

      verify_uploadable def upload(uploadable)
        uploadable
      end

      verify_id def get(id)
        id
      end
    end
  end
  let(:instance) { klass.new }

  describe "#verify_uploadable" do
    let(:io) { StringIO.new("hello") }

    it "works if it conforms to required API" do
      expect(instance.upload(double(size: 444, read: io, eof?: true, close: nil))).to be_truthy
    end

    it "raises ArgumentError if argument does not respond to `size`" do
      expect { instance.upload(double(read: io, eof?: true, close: nil)) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError if argument does not respond to `read`" do
      expect { instance.upload(double(size: 444, eof?: true, close: nil)) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError if argument does not respond to `eof?`" do
      expect { instance.upload(double(size: 444, read: true, close: nil)) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError if argument does not respond to `close`" do
      expect { instance.upload(double(size: 444, read: true, eof?: true)) }.to raise_error(ArgumentError)
    end

    it "returns true if size is respeced" do
      instance.max_size = 8
      expect(instance.upload(Refile::FileDouble.new("hello"))).to be_truthy
    end

    it "raises Refile::Invalid if size is exceeded" do
      instance.max_size = 8
      expect { instance.upload(Refile::FileDouble.new("hello world")) }.to raise_error(Refile::Invalid)
    end
  end

  describe "#verify_id" do
    it "works if it has a valid ID" do
      expect(instance.get("1234aBCde123aee")).to be_truthy
    end

    it "raises ArgumentError if argument does not respond to `size`" do
      expect { instance.get("ev/il") }.to raise_error(Refile::InvalidID)
    end
  end
end
