RSpec.shared_examples_for :store do
  def uploadable(data = "hello")
    double(size: data.length, to_io: StringIO.new(data))
  end

  describe "#cache" do
    it "raises ArgumentError when invalid object is uploaded" do
      expect { store.cache(double(size: 123)) }.to raise_error(ArgumentError)
      expect { store.cache("hello") }.to raise_error(ArgumentError)
    end

    it "caches file for later retrieval" do
      file = store.cache(uploadable)
      retrieved = store.retrieve(file.id)

      expect(retrieved.read).to eq("hello")
      expect(retrieved.size).to eq(5)
      expect(retrieved.exists?).to be_truthy
    end
  end

  describe "#store" do
    it "raises ArgumentError when invalid object is uploaded" do
      expect { store.store(double(size: 123)) }.to raise_error(ArgumentError)
      expect { store.store("hello") }.to raise_error(ArgumentError)
    end

    it "stores file for later retrieval" do
      file = store.store(uploadable)
      retrieved = store.retrieve(file.id)

      expect(retrieved.read).to eq("hello")
      expect(retrieved.size).to eq(5)
      expect(retrieved.exists?).to be_truthy
    end
  end

  describe "#delete" do
    it "removes a cached file" do
      file = store.cache(uploadable)

      store.delete(file.id)

      expect(store.retrieve(file.id).exists?).to be_falsy
    end

    it "removes a stored file" do
      file = store.store(uploadable)

      store.delete(file.id)

      expect(store.retrieve(file.id).exists?).to be_falsy
    end

    it "does not affect other files a stored file" do
      file = store.store(uploadable)
      other = store.store(uploadable)

      store.delete(file.id)

      expect(store.retrieve(file.id).exists?).to be_falsy
      expect(store.retrieve(other.id).exists?).to be_truthy
    end

    it "does nothing when file doesn't exist" do
      file = store.store(uploadable)

      store.delete(file.id)
      store.delete(file.id)
    end

    it "can be called through file" do
      file = store.store(uploadable)

      file.delete

      expect(store.retrieve(file.id).exists?).to be_falsy
    end
  end

  describe "#clear_cache!" do
    it "removes cached files" do
      file = store.cache(uploadable)

      store.clear_cache!

      expect(store.retrieve(file.id).exists?).to be_falsy
    end

    it "does not remove stored files" do
      file = store.store(uploadable)

      store.clear_cache!

      expect(store.retrieve(file.id).exists?).to be_truthy
    end
  end

  describe "#open" do
    it "opens an IO object from the file" do
      file = store.store(uploadable)

      expect(store.open(file.id).readpartial(4)).to eq("hell")
    end

    it "can be called with a block for automatic cleanup" do
      file = store.store(uploadable)

      result = store.open(file.id) { |file| file.readpartial(4) }

      expect(result).to eq("hell")
    end

    it "can be called through the file" do
      file = store.store(uploadable)

      expect(file.to_io.readpartial(4)).to eq("hell")
    end
  end
end
