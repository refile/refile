require "refile"

RSpec.describe Refile do
  describe ".extract_filename" do
    it "extracts filename from original_filename" do
      name = Refile.extract_filename(double(original_filename: "/foo/bar/baz.png"))
      expect(name).to eq("baz.png")
    end

    it "extracts filename from path" do
      name = Refile.extract_filename(double(path: "/foo/bar/baz.png"))
      expect(name).to eq("baz.png")
    end

    it "returns nil if it can't determine filename" do
      name = Refile.extract_filename(double)
      expect(name).to be_nil
    end
  end

  describe ".extract_content_type" do
    it "extracts content type" do
      name = Refile.extract_content_type(double(content_type: "image/jpeg"))
      expect(name).to eq("image/jpeg")
    end

    it "extracts content type from extension" do
      name = Refile.extract_content_type(double(original_filename: "test.png"))
      expect(name).to eq("image/png")
    end

    it "returns nil if it can't determine content type" do
      name = Refile.extract_filename(double)
      expect(name).to be_nil
    end

    it "returns nil if it has an unknown content type" do
      name = Refile.extract_content_type(double(original_filename: "foo.blah"))
      expect(name).to be_nil
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
      allow(Refile).to receive(:mount_point).and_return(nil)
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

      it "takes prefix from Refile.mount_point" do
        allow(Refile).to receive(:mount_point).and_return("attachments")
        expect(Refile.attachment_url(instance, :document)).to eq("/attachments/cache/#{id}/document")
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
