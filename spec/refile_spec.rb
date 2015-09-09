require "refile"

RSpec.describe Refile do
  before do
    allow(Refile).to receive(:token).and_return("token")
    allow(Refile).to receive(:app_host).and_return(nil)
    allow(Refile).to receive(:mount_point).and_return(nil)
  end

  let(:klass) do
    Class.new do
      extend Refile::Attachment
      attr_accessor :document_id
      attachment :document
    end
  end
  let(:instance) { klass.new }

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

  describe ".app_url" do
    it "generates a root url when all options unset" do
      expect(Refile.app_url).to eq("/")
    end

    it "uses supplied host option" do
      expect(Refile.app_url(host: "http://example.org")).to eq("http://example.org/")
    end

    it "falls back to Refile.app_host" do
      allow(Refile).to receive(:app_host).and_return("http://elabs.se")

      expect(Refile.app_url).to eq("http://elabs.se/")
    end

    it "adds a prefix" do
      expect(Refile.app_url(prefix: "/moo")).to eq("/moo")
    end

    it "takes prefix from Refile.mount_point" do
      allow(Refile).to receive(:mount_point).and_return("/attachments")
      expect(Refile.app_url).to eq("/attachments")
    end
  end

  describe ".file_url" do
    let(:file) { Refile.cache.upload(Refile::FileDouble.new("hello")) }
    let(:id) { file.id }

    it "generates a url from an attachment" do
      expect(Refile.file_url(file, filename: "document")).to eq("/token/cache/#{id}/document")
    end

    it "uses supplied host option" do
      expect(Refile.file_url(file, host: "http://example.org", filename: "document")).to eq("http://example.org/token/cache/#{id}/document")
    end

    it "falls back to Refile.app_host" do
      allow(Refile).to receive(:app_host).and_return("http://elabs.se")

      expect(Refile.file_url(file, filename: "document")).to eq("http://elabs.se/token/cache/#{id}/document")
    end

    it "falls back to Refile.cdn_host" do
      allow(Refile).to receive(:cdn_host).and_return("http://foo.cloudfront.com")
      allow(Refile).to receive(:app_host).and_return("http://elabs.se")

      expect(Refile.file_url(file, filename: "document")).to eq("http://foo.cloudfront.com/token/cache/#{id}/document")
    end

    it "adds a prefix" do
      expect(Refile.file_url(file, prefix: "/moo", filename: "document")).to eq("/moo/token/cache/#{id}/document")
    end

    it "takes prefix from Refile.mount_point" do
      allow(Refile).to receive(:mount_point).and_return("/attachments")
      expect(Refile.file_url(file, filename: "document")).to eq("/attachments/token/cache/#{id}/document")
    end

    it "adds an escaped filename" do
      expect(Refile.file_url(file, filename: "test.png")).to eq("/token/cache/#{id}/test.png")
      expect(Refile.file_url(file, filename: "tes/t.png")).to eq("/token/cache/#{id}/tes%2Ft.png")
    end

    it "adds a format" do
      expect(Refile.file_url(file, format: "png", filename: "document")).to eq("/token/cache/#{id}/document.png")
    end

    context "with no file" do
      it "returns nil" do
        expect(Refile.file_url(nil, filename: "document")).to be_nil
      end
    end
  end

  describe ".attachment_url" do
    let(:id) { instance.document_attacher.cache_id }

    context "with file" do
      before do
        instance.document = Refile::FileDouble.new("hello")
      end

      it "generates a url from an attachment" do
        expect(Refile.attachment_url(instance, :document)).to eq("/token/cache/#{id}/document")
      end

      it "uses supplied host option" do
        expect(Refile.attachment_url(instance, :document, host: "http://example.org")).to eq("http://example.org/token/cache/#{id}/document")
      end

      it "falls back to Refile.app_host" do
        allow(Refile).to receive(:app_host).and_return("http://elabs.se")

        expect(Refile.attachment_url(instance, :document)).to eq("http://elabs.se/token/cache/#{id}/document")
      end

      it "falls back to Refile.cdn_host" do
        allow(Refile).to receive(:cdn_host).and_return("http://foo.cloudfront.com")
        allow(Refile).to receive(:app_host).and_return("http://elabs.se")

        expect(Refile.attachment_url(instance, :document)).to eq("http://foo.cloudfront.com/token/cache/#{id}/document")
      end

      it "adds a prefix" do
        expect(Refile.attachment_url(instance, :document, prefix: "/moo")).to eq("/moo/token/cache/#{id}/document")
      end

      it "takes prefix from Refile.mount_point" do
        allow(Refile).to receive(:mount_point).and_return("/attachments")
        expect(Refile.attachment_url(instance, :document)).to eq("/attachments/token/cache/#{id}/document")
      end

      it "adds an escaped filename" do
        expect(Refile.attachment_url(instance, :document, filename: "test.png")).to eq("/token/cache/#{id}/test.png")
        expect(Refile.attachment_url(instance, :document, filename: "tes/t.png")).to eq("/token/cache/#{id}/tes%2Ft.png")
      end

      it "adds a format" do
        expect(Refile.attachment_url(instance, :document, format: "png")).to eq("/token/cache/#{id}/document.png")
      end
    end

    context "with file with content type" do
      before do
        instance.document = Refile::FileDouble.new("hello", content_type: "image/png")
      end

      it "adds format inferred from content type" do
        expect(Refile.attachment_url(instance, :document)).to eq("/token/cache/#{id}/document.png")
      end
    end

    context "with file with filename" do
      before do
        instance.document = Refile::FileDouble.new("hello", "hello.html")
      end

      it "adds filename" do
        expect(Refile.attachment_url(instance, :document)).to eq("/token/cache/#{id}/hello.html")
      end
    end

    context "with no file" do
      it "returns nil" do
        expect(Refile.attachment_url(instance, :document)).to be_nil
      end
    end
  end

  describe ".upload_url" do
    it "generates an upload url" do
      expect(Refile.upload_url(Refile.cache)).to eq("/cache")
    end

    it "uses supplied host option" do
      expect(Refile.upload_url(Refile.cache, host: "http://example.org")).to eq("http://example.org/cache")
    end

    it "falls back to Refile.app_host" do
      allow(Refile).to receive(:app_host).and_return("http://elabs.se")

      expect(Refile.upload_url(Refile.cache)).to eq("http://elabs.se/cache")
    end

    it "does not fall back to Refile.cdn_host" do
      allow(Refile).to receive(:cdn_host).and_return("http://foo.cloudfront.com")

      expect(Refile.upload_url(Refile.cache)).to eq("/cache")
    end

    it "adds a prefix" do
      expect(Refile.upload_url(Refile.cache, prefix: "/moo")).to eq("/moo/cache")
    end

    it "takes prefix from Refile.mount_point" do
      allow(Refile).to receive(:mount_point).and_return("/attachments")
      expect(Refile.upload_url(Refile.cache)).to eq("/attachments/cache")
    end
  end

  describe ".presign_url" do
    it "generates an upload url" do
      expect(Refile.presign_url(Refile.cache)).to eq("/cache/presign")
    end

    it "uses supplied host option" do
      expect(Refile.presign_url(Refile.cache, host: "http://example.org")).to eq("http://example.org/cache/presign")
    end

    it "falls back to Refile.app_host" do
      allow(Refile).to receive(:app_host).and_return("http://elabs.se")

      expect(Refile.presign_url(Refile.cache)).to eq("http://elabs.se/cache/presign")
    end

    it "does not fall back to Refile.cdn_host" do
      allow(Refile).to receive(:cdn_host).and_return("http://foo.cloudfront.com")

      expect(Refile.presign_url(Refile.cache)).to eq("/cache/presign")
    end

    it "adds a prefix" do
      expect(Refile.presign_url(Refile.cache, prefix: "/moo")).to eq("/moo/cache/presign")
    end

    it "takes prefix from Refile.mount_point" do
      allow(Refile).to receive(:mount_point).and_return("/attachments")
      expect(Refile.presign_url(Refile.cache)).to eq("/attachments/cache/presign")
    end
  end

  describe ".attachment_upload_url" do
    it "generates an upload url" do
      expect(Refile.attachment_upload_url(instance, :document)).to eq("/cache")
    end

    it "uses supplied host option" do
      expect(Refile.attachment_upload_url(instance, :document, host: "http://example.org")).to eq("http://example.org/cache")
    end

    it "falls back to Refile.app_host" do
      allow(Refile).to receive(:app_host).and_return("http://elabs.se")

      expect(Refile.attachment_upload_url(instance, :document)).to eq("http://elabs.se/cache")
    end

    it "does not fall back to Refile.cdn_host" do
      allow(Refile).to receive(:cdn_host).and_return("http://foo.cloudfront.com")

      expect(Refile.attachment_upload_url(instance, :document)).to eq("/cache")
    end

    it "adds a prefix" do
      expect(Refile.attachment_upload_url(instance, :document, prefix: "/moo")).to eq("/moo/cache")
    end

    it "takes prefix from Refile.mount_point" do
      allow(Refile).to receive(:mount_point).and_return("/attachments")
      expect(Refile.attachment_upload_url(instance, :document)).to eq("/attachments/cache")
    end
  end

  describe ".attachment_presign_url" do
    it "generates an upload url" do
      expect(Refile.attachment_presign_url(instance, :document)).to eq("/cache/presign")
    end

    it "uses supplied host option" do
      expect(Refile.attachment_presign_url(instance, :document, host: "http://example.org")).to eq("http://example.org/cache/presign")
    end

    it "falls back to Refile.app_host" do
      allow(Refile).to receive(:app_host).and_return("http://elabs.se")

      expect(Refile.attachment_presign_url(instance, :document)).to eq("http://elabs.se/cache/presign")
    end

    it "does not fall back to Refile.cdn_host" do
      allow(Refile).to receive(:cdn_host).and_return("http://foo.cloudfront.com")

      expect(Refile.attachment_presign_url(instance, :document)).to eq("/cache/presign")
    end

    it "adds a prefix" do
      expect(Refile.attachment_presign_url(instance, :document, prefix: "/moo")).to eq("/moo/cache/presign")
    end

    it "takes prefix from Refile.mount_point" do
      allow(Refile).to receive(:mount_point).and_return("/attachments")
      expect(Refile.attachment_presign_url(instance, :document)).to eq("/attachments/cache/presign")
    end
  end

  describe ".token" do
    before do
      allow(Refile).to receive(:token).and_call_original
    end

    it "returns digest of given path and secret token" do
      allow(Refile).to receive(:secret_key).and_return("abcd1234")

      path = "/store/f5f2e4/document.pdf"
      token = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), "abcd1234", path)
      expect(Refile.token(path)).to eq(token)
    end

    it "returns raise error when secret token is nil" do
      allow(Refile).to receive(:secret_key).and_return(nil)

      expect { Refile.token("/store/f5f2e4/document.pdf") }.to raise_error(RuntimeError, /Refile\.secret_key was not set/)
    end
  end
end
