RSpec.shared_examples_for :store do
  let(:uploadable) { double(read: "hello", size: 5) }

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
end
