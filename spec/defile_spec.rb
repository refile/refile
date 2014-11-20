require "defile"

RSpec.describe Defile do
  let(:io) { StringIO.new("hello") }

  describe ".verify_uploadable" do
    it "works if it can be cast to io" do
      expect(Defile.verify_uploadable(double(size: 444, to_io: io))).to be_truthy
    end

    it "works if it can be streamed" do
      expect(Defile.verify_uploadable(double(size: 444, stream: ["hello"].each))).to be_truthy
    end

    it "raises ArgumentError if argument does not respond to `size`" do
      expect { Defile.verify_uploadable(double(to_io: io)) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError if argument does not respond to `to_io` or `stream`" do
      expect { Defile.verify_uploadable(double(size: 1234)) }.to raise_error(ArgumentError)
    end
  end

  describe ".stream" do
    it "returns an iterator over an io object" do
      stream = Defile.stream(double(size: 444, to_io: io))

      expect(stream).to be_an_instance_of(Enumerator)
      expect(stream.to_a.join).to eq("hello")
    end

    it "returns an iterator over a stream" do
      stream = Defile.stream(double(size: 444, to_io: io, stream: ["hello", "world"].each))

      expect(stream).to be_an_instance_of(Enumerator)
      expect(stream.to_a.join).to eq("helloworld")
    end
  end
end
