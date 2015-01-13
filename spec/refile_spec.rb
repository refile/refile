require "refile"

RSpec.describe Refile do
  let(:io) { StringIO.new("hello") }

  describe ".verify_uploadable" do
    it "returns true if size is respeced" do
      expect(Refile.verify_uploadable(Refile::FileDouble.new("hello"), 8)).to be_truthy
    end

    it "raises Refile::Invalid if size is exceeded" do
      expect { Refile.verify_uploadable(Refile::FileDouble.new("hello world"), 8) }.to raise_error(Refile::Invalid)
    end
  end

  describe ".attachment_url" do
    let(:klass) do
      Class.new do
        extend Refile::Attachment
        attachment :document
      end
    end
    let(:instance) { klass.new }
    let(:id) { instance.document_attacher.cache_id }

    before do
      allow(Refile).to receive(:host).and_return(nil)
    end

    context "with file" do
      before do
        instance.document = Refile::FileDouble.new("hello")
      end

      it "generates a url from an attachment" do
        expect(Refile.attachment_url(instance, :document)).to eq("/cache/#{id}/document")
      end

      it "uses supplied host option" do
        expect(Refile.attachment_url(instance, :document, host: "http://example.org")).to eq("http://example.org/cache/#{id}/document")
      end

      it "falls back to Refile.host" do
        allow(Refile).to receive(:host).and_return("http://elabs.se")

        expect(Refile.attachment_url(instance, :document)).to eq("http://elabs.se/cache/#{id}/document")
      end

      it "adds a prefix" do
        expect(Refile.attachment_url(instance, :document, prefix: "moo")).to eq("/moo/cache/#{id}/document")
      end

      it "adds an escaped filename" do
        expect(Refile.attachment_url(instance, :document, filename: "test.png")).to eq("/cache/#{id}/test.png")
        expect(Refile.attachment_url(instance, :document, filename: "tes/t.png")).to eq("/cache/#{id}/tes%2Ft.png")
      end

      it "adds a format" do
        expect(Refile.attachment_url(instance, :document, format: "png")).to eq("/cache/#{id}/document.png")
      end
    end

    context "with file with content type" do
      before do
        instance.document = Refile::FileDouble.new("hello", content_type: "image/png")
      end

      it "adds format inferred from content type" do
        expect(Refile.attachment_url(instance, :document)).to eq("/cache/#{id}/document.png")
      end
    end

    context "with file with filename" do
      before do
        instance.document = Refile::FileDouble.new("hello", "hello.html")
      end

      it "adds filename" do
        expect(Refile.attachment_url(instance, :document)).to eq("/cache/#{id}/hello.html")
      end
    end

    context "with no file" do
      it "returns nil" do
        expect(Refile.attachment_url(instance, :document)).to be_nil
      end
    end
  end
end
