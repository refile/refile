describe Refile::Attachment do
  let(:options) { { } }
  let(:post) { Post.new }
  let(:klass) do
    opts = options
    Class.new do
      extend Refile::Attachment

      attr_accessor :document_id, :document_name, :document_size

      attachment :document, **opts
    end
  end
  let(:instance) { klass.new }

  describe ":name=" do
    it "receives a file, caches it and sets the _id parameter" do
      instance.document = Refile::FileDouble.new("hello")

      expect(Refile.cache.get(instance.document.id).read).to eq("hello")
      expect(Refile.cache.get(instance.document_cache_id).read).to eq("hello")
    end
  end

  describe ":name" do
    it "gets a file from the store" do
      file = Refile.store.upload(Refile::FileDouble.new("hello"))
      instance.document_id = file.id

      expect(instance.document.id).to eq(file.id)
    end
  end

  describe "remote_:name_url=" do
    it "does nothign when nil is assigned" do
      instance.remote_document_url = nil
      expect(instance.document).to be_nil
    end

    it "does nothign when empty string is assigned" do
      instance.remote_document_url = nil
      expect(instance.document).to be_nil
    end

    context "without redirects" do
      before(:each) do
        stub_request(:get, "http://www.example.com/some_file").to_return(status: 200, body: "abc", headers: { "Content-Length" => 3 })
      end

      it "downloads file, caches it and sets the _id parameter" do
        instance.remote_document_url = "http://www.example.com/some_file"
        expect(Refile.cache.get(instance.document.id).read).to eq("abc")
        expect(Refile.cache.get(instance.document_cache_id).read).to eq("abc")
      end
    end

    context "with redirects" do
      before(:each) do
        stub_request(:get, "http://www.example.com/1").to_return(status: 302, headers: { "Location" => "http://www.example.com/2" })
        stub_request(:get, "http://www.example.com/2").to_return(status: 200, body: "woop", headers: { "Content-Length" => 4 })
        stub_request(:get, "http://www.example.com/loop").to_return(status: 302, headers: { "Location" => "http://www.example.com/loop" })
      end

      it "follows redirects and fetches the file, caches it and sets the _id parameter" do
        instance.remote_document_url = "http://www.example.com/1"
        expect(Refile.cache.get(instance.document.id).read).to eq("woop")
        expect(Refile.cache.get(instance.document_cache_id).read).to eq("woop")
      end

      context "when errors enabled" do
        let(:options) { { raise_errors: true } }
        it "handles redirect loops by trowing errors" do
          expect do
            instance.remote_document_url = "http://www.example.com/loop"
          end.to raise_error(RestClient::MaxRedirectsReached)
        end
      end

      context "when errors disabled" do
        let(:options) { { raise_errors: false } }
        it "handles redirect loops by setting generic download error" do
          expect do
            instance.remote_document_url = "http://www.example.com/loop"
          end.not_to raise_error
          expect(instance.document_attachment.errors).to eq([:download_failed])
          expect(instance.document).to be_nil
        end
      end
    end
  end

  describe ":name_cache_id" do
    it "doesn't overwrite a cached file" do
      instance.document = Refile::FileDouble.new("hello")
      instance.document_cache_id = "xyz"

      expect(instance.document.read).to eq("hello")
    end
  end

  describe ":name_attachment.store!" do
    it "puts a cached file into the store" do
      instance.document = Refile::FileDouble.new("hello")
      cache = instance.document

      instance.document_attachment.store!

      expect(Refile.store.get(instance.document_id).read).to eq("hello")
      expect(Refile.store.get(instance.document.id).read).to eq("hello")

      expect(instance.document_cache_id).to be_nil
      expect(Refile.cache.get(cache.id).exists?).to be_falsy
    end

    it "does nothing when not cached" do
      file = Refile.store.upload(Refile::FileDouble.new("hello"))
      instance.document_id = file.id

      instance.document_attachment.store!

      expect(Refile.store.get(instance.document_id).read).to eq("hello")
      expect(Refile.store.get(instance.document.id).read).to eq("hello")
    end

    it "overwrites previously stored file" do
      file = Refile.store.upload(Refile::FileDouble.new("hello"))
      instance.document_id = file.id

      instance.document = Refile::FileDouble.new("world")
      cache = instance.document

      instance.document_attachment.store!

      expect(Refile.store.get(instance.document_id).read).to eq("world")
      expect(Refile.store.get(instance.document.id).read).to eq("world")

      expect(instance.document_cache_id).to be_nil
      expect(Refile.cache.get(cache.id).exists?).to be_falsy
      expect(Refile.store.get(file.id).exists?).to be_falsy
    end

    it "removes an uploaded file when remove? returns true" do
      file = Refile.store.upload(Refile::FileDouble.new("hello"))
      instance.document_id = file.id

      instance.document_attachment.remove = true
      instance.document_attachment.store!

      expect(instance.document_id).to be_nil
      expect(Refile.store.exists?(file.id)).to be_falsy
    end
  end

  describe ":name_attachment.delete!" do
    it "deletes a stored file" do
      file = Refile.store.upload(Refile::FileDouble.new("hello"))
      instance.document_id = file.id

      instance.document_attachment.delete!

      expect(instance.document_id).to be_nil
      expect(Refile.store.exists?(file.id)).to be_falsy
    end

    it "deletes a cached file" do
      file = Refile.cache.upload(Refile::FileDouble.new("hello"))
      instance.document_cache_id = file.id

      instance.document_attachment.delete!

      expect(instance.document_id).to be_nil
      expect(instance.document_cache_id).to be_nil
      expect(Refile.cache.exists?(file.id)).to be_falsy
    end
  end

  describe ":name_attachment.remove?" do
    it "should be true when the value is truthy" do
      instance.document_attachment.remove = true
      expect(instance.document_attachment.remove?).to be_truthy
    end

    it "should be false when the value is falsey" do
      instance.document_attachment.remove = false
      expect(instance.document_attachment.remove?).to be_falsy
    end

    it "should be false when the value is ''" do
      instance.document_attachment.remove = ''
      expect(instance.document_attachment.remove?).to be_falsy
    end

    it "should be false when the value is '0'" do
      instance.document_attachment.remove = '0'
      expect(instance.document_attachment.remove?).to be_falsy
    end

    it "should be false when the value is 'false'" do
      instance.document_attachment.remove = 'false'
      expect(instance.document_attachment.remove?).to be_falsy
    end
  end

  describe ":name_attachment.error" do
    let(:options) { { cache: :limited_cache, raise_errors: false } }

    it "is blank when valid file uploaded" do
      file = Refile::FileDouble.new("hello")
      instance.document = file

      expect(instance.document_attachment.errors).to be_empty
      expect(Refile.cache.get(instance.document.id).exists?).to be_truthy
    end

    it "contains a list of errors when invalid file uploaded" do
      file = Refile::FileDouble.new("a"*120)
      instance.document = file

      expect(instance.document_attachment.errors).to eq([:too_large])
      expect(instance.document).to be_nil
    end

    it "is reset when valid file uploaded" do
      file = Refile::FileDouble.new("a"*120)
      instance.document = file

      file = Refile::FileDouble.new("hello")
      instance.document = file

      expect(instance.document_attachment.errors).to be_empty
      expect(Refile.cache.get(instance.document.id).exists?).to be_truthy
    end
  end

  describe "with option `raise_errors: true" do
    let(:options) { { cache: :limited_cache, raise_errors: true } }

    it "raises an error when invalid file assigned" do
      file = Refile::FileDouble.new("a"*120)
      expect do
        instance.document = file
      end.to raise_error(Refile::Invalid)

      expect(instance.document_attachment.errors).to eq([:too_large])
      expect(instance.document).to be_nil
    end
  end

  describe "with option `raise_errors: false" do
    let(:options) { { cache: :limited_cache, raise_errors: false } }

    it "does not raise an error when invalid file assigned" do
      file = Refile::FileDouble.new("a"*120)
      instance.document = file

      expect(instance.document_attachment.errors).to eq([:too_large])
      expect(instance.document).to be_nil
    end
  end
end
