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
