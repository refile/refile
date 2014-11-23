describe Defile::Attachment do
  let(:options) { { } }
  let(:post) { Post.new }
  let(:klass) do
    opts = options
    Class.new do
      extend Defile::Attachment

      attr_accessor :document_id, :document_name, :document_size

      attachment :document, **opts
    end
  end
  let(:instance) { klass.new }

  describe ":name=" do
    it "receives a file, caches it and sets the _id parameter" do
      instance.document = Defile::FileDouble.new("hello")

      expect(Defile.cache.get(instance.document.id).read).to eq("hello")
      expect(Defile.cache.get(instance.document_cache_id).read).to eq("hello")
    end
  end

  describe ":name" do
    it "gets a file from the store" do
      file = Defile.store.upload(Defile::FileDouble.new("hello"))
      instance.document_id = file.id

      expect(instance.document.id).to eq(file.id)
    end
  end

  describe ":name_cache_id" do
    it "doesn't overwrite a cached file" do
      instance.document = Defile::FileDouble.new("hello")
      instance.document_cache_id = "xyz"

      expect(instance.document.read).to eq("hello")
    end
  end

  describe ":name_attachment.store!" do
    it "puts a cached file into the store" do
      instance.document = Defile::FileDouble.new("hello")
      cache = instance.document

      instance.document_attachment.store!

      expect(Defile.store.get(instance.document_id).read).to eq("hello")
      expect(Defile.store.get(instance.document.id).read).to eq("hello")

      expect(instance.document_cache_id).to be_nil
      expect(Defile.cache.get(cache.id).exists?).to be_falsy
    end

    it "does nothing when not cached" do
      file = Defile.store.upload(Defile::FileDouble.new("hello"))
      instance.document_id = file.id

      instance.document_attachment.store!

      expect(Defile.store.get(instance.document_id).read).to eq("hello")
      expect(Defile.store.get(instance.document.id).read).to eq("hello")
    end

    it "overwrites previously stored file" do
      file = Defile.store.upload(Defile::FileDouble.new("hello"))
      instance.document_id = file.id

      instance.document = Defile::FileDouble.new("world")
      cache = instance.document

      instance.document_attachment.store!

      expect(Defile.store.get(instance.document_id).read).to eq("world")
      expect(Defile.store.get(instance.document.id).read).to eq("world")

      expect(instance.document_cache_id).to be_nil
      expect(Defile.cache.get(cache.id).exists?).to be_falsy
      expect(Defile.store.get(file.id).exists?).to be_falsy
    end
  end

  describe ":name_attachment.error" do
    let(:options) { { cache: :limited_cache, raise_errors: false } }

    it "is blank when valid file uploaded" do
      file = Defile::FileDouble.new("hello")
      instance.document = file

      expect(instance.document_attachment.errors).to be_empty
      expect(Defile.cache.get(instance.document.id).exists?).to be_truthy
    end

    it "contains a list of errors when invalid file uploaded" do
      file = Defile::FileDouble.new("a"*120)
      instance.document = file

      expect(instance.document_attachment.errors).to eq([:too_large])
      expect(instance.document).to be_nil
    end

    it "is reset when valid file uploaded" do
      file = Defile::FileDouble.new("a"*120)
      instance.document = file

      file = Defile::FileDouble.new("hello")
      instance.document = file

      expect(instance.document_attachment.errors).to be_empty
      expect(Defile.cache.get(instance.document.id).exists?).to be_truthy
    end
  end

  describe "with option `raise_errors: true" do
    let(:options) { { cache: :limited_cache, raise_errors: true } }

    it "raises an error when invalid file assigned" do
      file = Defile::FileDouble.new("a"*120)
      expect do
        instance.document = file
      end.to raise_error(Defile::Invalid)

      expect(instance.document_attachment.errors).to eq([:too_large])
      expect(instance.document).to be_nil
    end
  end

  describe "with option `raise_errors: false" do
    let(:options) { { cache: :limited_cache, raise_errors: false } }

    it "does not raise an error when invalid file assigned" do
      file = Defile::FileDouble.new("a"*120)
      instance.document = file

      expect(instance.document_attachment.errors).to eq([:too_large])
      expect(instance.document).to be_nil
    end
  end
end
