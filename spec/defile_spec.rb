require "defile"

RSpec.describe Defile do
  let(:io) { StringIO.new("foo") }

  describe ".verify_uploadable" do
    it "returns true if argument is a legit uploadable" do
      expect(Defile.verify_uploadable(double(size: 444, to_io: io))).to be_truthy
    end

    it "raises ArgumentError if argument does not respond to `size`" do
      expect { Defile.verify_uploadable(double(to_io: io)) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError if argument does not respond to `to_io`" do
      expect { Defile.verify_uploadable(double(size: 1234)) }.to raise_error(ArgumentError)
    end
  end
end
