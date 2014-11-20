describe Defile::Attachment do
  let(:post) { Post.new }
  let(:klass) do
    Class.new do
      extend Defile::Attachment

      attr_accessor :image_id, :image_name, :image_size

      attachment :image, type: :image
    end
  end
  let(:instance) { klass.new }

  describe ":name=" do
    it "receives a file, caches it and sets the _id parameter" do
      instance.image = Defile::FileDouble.new("hello")

      expect(Defile.cache.get(instance.image.id).read).to eq("hello")
      expect(Defile.cache.get(instance.image_cache_id).read).to eq("hello")
    end
  end

  describe ":name" do
    it "gets a file from the store" do
      file = Defile.store.upload(Defile::FileDouble.new("hello"))
      instance.image_id = file.id

      expect(instance.image.id).to eq(file.id)
    end
  end

  describe "store_:name" do
    it "puts a cached file into the store" do
      instance.image = Defile::FileDouble.new("hello")
      cache = instance.image

      instance.store_image

      expect(Defile.store.get(instance.image_id).read).to eq("hello")
      expect(Defile.store.get(instance.image.id).read).to eq("hello")

      expect(instance.image_cache_id).to be_nil
      expect(Defile.cache.get(cache.id).exists?).to be_falsy
    end

    it "overwrites previously stored file" do
      file = Defile.store.upload(Defile::FileDouble.new("hello"))
      instance.image_id = file.id

      instance.image = Defile::FileDouble.new("world")
      cache = instance.image

      instance.store_image

      expect(Defile.store.get(instance.image_id).read).to eq("world")
      expect(Defile.store.get(instance.image.id).read).to eq("world")

      expect(instance.image_cache_id).to be_nil
      expect(Defile.cache.get(cache.id).exists?).to be_falsy
    end
  end
end
