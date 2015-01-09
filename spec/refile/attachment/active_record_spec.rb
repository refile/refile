require "refile/active_record_helper"
require "refile/attachment/active_record"

describe Refile::ActiveRecord::Attachment do
  let(:options) { {} }
  let(:klass) do
    opts = options
    Class.new(ActiveRecord::Base) do
      self.table_name = :posts

      def self.name
        "Post"
      end

      attachment :document, **opts
    end
  end

  describe "#valid?" do
    let(:options) { { type: :image } }

    context "with file" do
      it "returns true when no file is assigned" do
        post = klass.new
        expect(post.valid?).to be_truthy
        expect(post.errors[:document]).to be_empty
      end

      it "returns false when type is invalid" do
        post = klass.new
        post.document = Refile::FileDouble.new("hello", content_type: "text/plain")
        expect(post.valid?).to be_falsy
        expect(post.errors[:document].length).to eq(1)
      end

      it "returns true when type is invalid" do
        post = klass.new
        post.document = Refile::FileDouble.new("hello", content_type: "image/png")
        expect(post.valid?).to be_truthy
        expect(post.errors[:document]).to be_empty
      end
    end

    context "with metadata" do
      it "returns false when metadata doesn't have an id" do
        Refile.cache.upload(StringIO.new("hello"))
        post = klass.new
        post.document = { content_type: "text/png" }.to_json
        expect(post.valid?).to be_falsy
        expect(post.errors[:document].length).to eq(1)
      end

      it "returns false when type is invalid" do
        file = Refile.cache.upload(StringIO.new("hello"))
        post = klass.new
        post.document = { id: file.id, content_type: "text/png" }.to_json
        expect(post.valid?).to be_falsy
        expect(post.errors[:document].length).to eq(1)
      end

      it "returns true when type is invalid" do
        file = Refile.cache.upload(StringIO.new("hello"))
        post = klass.new
        post.document = { id: file.id, content_type: "image/png" }.to_json
        expect(post.valid?).to be_truthy
        expect(post.errors[:document]).to be_empty
      end
    end
  end

  describe "#save" do
    it "stores the assigned file" do
      post = klass.new
      post.document = Refile::FileDouble.new("hello")
      post.save
      post = klass.find(post.id)
      expect(post.document.read).to eq("hello")
      expect(Refile.store.read(post.document.id)).to eq("hello")
    end
  end

  describe "#destroy" do
    it "removes the stored file" do
      post = klass.new
      post.document = Refile::FileDouble.new("hello")
      post.save
      file = post.document
      post.destroy
      expect(file.exists?).to be_falsy
    end
  end
end
