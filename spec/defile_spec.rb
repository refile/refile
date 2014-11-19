require "defile"

RSpec.describe Defile do
  describe ".verify_uploadable" do
    it "returns true if argument is a legit uploadable" do
      expect(Defile.verify_uploadable(double(read: "1234", size: 444))).to be_truthy
    end

    it "raises ArgumentError if argument does not respond to `size`" do
      expect { Defile.verify_uploadable(double(read: "1234")) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError if argument does not respond to `read`" do
      expect { Defile.verify_uploadable(double(size: 1234)) }.to raise_error(ArgumentError)
    end
  end
end
