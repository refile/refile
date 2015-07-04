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
    let(:options) { { type: :image, cache: :limited_cache } }

    context "extension validation" do
      let(:options) { { cache: :limited_cache, extension: %w[Png] } }

      context "with file" do
        it "returns true when extension is included in list" do
          post = klass.new
          post.document = Refile::FileDouble.new("hello", "image.Png")
          expect(post.valid?).to be_truthy
          expect(post.errors[:document]).to be_empty
        end

        it "returns true when extension is included in list but chars are randomcase" do
          post = klass.new
          post.document = Refile::FileDouble.new("hello", "image.PNG")
          expect(post.valid?).to be_truthy
          expect(post.errors[:document]).to be_empty
        end

        it "returns false when extension is invalid" do
          post = klass.new
          post.document = Refile::FileDouble.new("hello", "image.jpg")
          expect(post.valid?).to be_falsy
          expect(post.errors[:document].length).to eq(1)
        end
      end

      context "with metadata" do
        it "returns true when extension is included in list" do
          file = Refile.cache.upload(StringIO.new("hello"))
          post = klass.new
          post.document = { id: file.id, filename: "image.Png" }.to_json
          expect(post.valid?).to be_truthy
          expect(post.errors[:document]).to be_empty
        end

        it "returns true when extension is included in list but chars are randomcase" do
          file = Refile.cache.upload(StringIO.new("hello"))
          post = klass.new
          post.document = { id: file.id, filename: "image.PNG" }.to_json
          expect(post.valid?).to be_truthy
          expect(post.errors[:document]).to be_empty
        end

        it "returns false when extension is invalid" do
          file = Refile.cache.upload(StringIO.new("hello"))
          post = klass.new
          post.document = { id: file.id, filename: "image.jpg" }.to_json
          expect(post.valid?).to be_falsy
          expect(post.errors[:document].length).to eq(1)
        end
      end
    end

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

      it "returns false when it has multiple errors" do
        post = klass.new
        post.document = Refile::FileDouble.new("h" * 200, content_type: "text/plain")
        expect(post.valid?).to be_falsy
        expect(post.errors[:document].length).to eq(2)
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

    it "replaces an existing file" do
      post = klass.new
      post.document = Refile::FileDouble.new("hello")
      post.save
      old_document = post.document

      post = klass.find(post.id)
      post.document = Refile::FileDouble.new("hello")
      post.save

      expect(Refile.store.read(post.document.id)).to eq("hello")
      expect(post.document.id).not_to be eq old_document.id
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

  describe ".accepts_nested_attributes_for" do
    let(:options) { {} }
    let(:post_class) do
      opts = options
      foo = document_class
      Class.new(ActiveRecord::Base) do
        self.table_name = :posts

        def self.name
          "Post"
        end

        has_many :documents, anonymous_class: foo, dependent: :destroy
        accepts_attachments_for :documents, **opts
      end
    end

    let(:document_class) do
      Class.new(ActiveRecord::Base) do
        self.table_name = :documents

        def self.name
          "Document"
        end

        attachment :file
      end
    end

    let(:post) { post_class.new }

    describe "#:association_:name" do
      it "builds records from assigned files" do
        post.documents_files = [Refile::FileDouble.new("hello"), Refile::FileDouble.new("world")]
        expect(post.documents[0].file.read).to eq("hello")
        expect(post.documents[1].file.read).to eq("world")
        expect(post.documents.size).to eq(2)
      end

      it "builds records from cache" do
        post.documents_files = [
          [
            { id: Refile.cache.upload(Refile::FileDouble.new("hello")).id },
            { id: Refile.cache.upload(Refile::FileDouble.new("world")).id }
          ].to_json
        ]
        expect(post.documents[0].file.read).to eq("hello")
        expect(post.documents[1].file.read).to eq("world")
        expect(post.documents.size).to eq(2)
      end

      it "prefers newly uploaded files over cache" do
        post.documents_files = [
          [
            { id: Refile.cache.upload(Refile::FileDouble.new("moo")).id }
          ].to_json,
          Refile::FileDouble.new("hello"),
          Refile::FileDouble.new("world")
        ]
        expect(post.documents[0].file.read).to eq("hello")
        expect(post.documents[1].file.read).to eq("world")
        expect(post.documents.size).to eq(2)
      end

      it "clears previously assigned files" do
        post.documents_files = [
          Refile::FileDouble.new("hello"),
          Refile::FileDouble.new("world")
        ]
        post.save
        post.update_attributes documents_files: [
          Refile::FileDouble.new("foo")
        ]
        retrieved = post_class.find(post.id)
        expect(retrieved.documents[0].file.read).to eq("foo")
        expect(retrieved.documents.size).to eq(1)
      end

      context "with append: true" do
        let(:options) { { append: true } }

        it "appends to previously assigned files" do
          post.documents_files = [
            Refile::FileDouble.new("hello"),
            Refile::FileDouble.new("world")
          ]
          post.save
          post.update_attributes documents_files: [
            Refile::FileDouble.new("foo")
          ]
          retrieved = post_class.find(post.id)
          expect(retrieved.documents[0].file.read).to eq("hello")
          expect(retrieved.documents[1].file.read).to eq("world")
          expect(retrieved.documents[2].file.read).to eq("foo")
          expect(retrieved.documents.size).to eq(3)
        end

        it "appends to previously assigned files with cached files" do
          post.documents_files = [
            Refile::FileDouble.new("hello"),
            Refile::FileDouble.new("world")
          ]
          post.save
          post.update_attributes documents_files: [
            [{
              id: Refile.cache.upload(Refile::FileDouble.new("hello")).id,
              filename: "some.jpg",
              content_type: "image/jpeg",
              size: 1234
            }].to_json
          ]
          retrieved = post_class.find(post.id)
          expect(retrieved.documents.size).to eq(3)
        end
      end
    end

    describe "#:association_:name_data" do
      it "returns metadata of all files" do
        post.documents_files = [nil, Refile::FileDouble.new("hello"), Refile::FileDouble.new("world")]
        data = post.documents_files_data
        expect(Refile.cache.read(data[0][:id])).to eq("hello")
        expect(Refile.cache.read(data[1][:id])).to eq("world")
        expect(data.size).to eq(2)
      end
    end
  end

  context "when attachment assigned to nested model" do
    let(:base_users_class) do
      Class.new(ActiveRecord::Base) do
        self.table_name = :users

        def self.name
          "User"
        end
      end
    end

    context "when model has one nested attachment" do
      let(:users_class) do
        posts_class = klass
        base_users_class.tap do |klass|
          klass.instance_eval do
            has_one :post, anonymous_class: posts_class
            accepts_nested_attributes_for :post
          end
        end
      end

      describe "#save" do
        it "stores the assigned file" do
          user = users_class.create! post_attributes: { document: Refile::FileDouble.new("foo") }

          post = user.post.reload
          expect(post.document.read).to eq("foo")
          expect(Refile.store.read(post.document.id)).to eq("foo")
        end

        it "removes files marked for removal" do
          user = users_class.create!
          post = klass.create!(user_id: user.id, document: Refile::FileDouble.new("foo"))

          user.update_attributes!(post_attributes: { id: post.id, remove_document: true })

          expect(post.reload.document).to be_nil
        end

        it "replaces an existing file" do
          user = users_class.create! post_attributes: { document: Refile::FileDouble.new("foo") }
          post = user.post

          user.update! post_attributes: { id: post.id, document: Refile::FileDouble.new("bar") }

          post.reload
          expect(post.document.read).to eq("bar")
          expect(Refile.store.read(post.document.id)).to eq("bar")
        end
      end
    end

    context "when model has many nested attachments" do
      let(:users_class) do
        posts_class = klass
        base_users_class.tap do |klass|
          klass.instance_eval do
            has_many :posts, anonymous_class: posts_class
            accepts_nested_attributes_for :posts
          end
        end
      end

      describe "#save" do
        it "stores the assigned file" do
          user = users_class.create! posts_attributes: [{ document: Refile::FileDouble.new("foo") }]

          post = user.posts.first.reload
          expect(post.document.read).to eq("foo")
          expect(Refile.store.read(post.document.id)).to eq("foo")
        end

        it "removes files marked for removal" do
          user = users_class.create!
          post = klass.create!(user_id: user.id, document: Refile::FileDouble.new("foo"))

          user.update_attributes!(posts_attributes: { id: post.id, remove_document: true })

          expect(post.reload.document).to be_nil
        end

        it "replaces an existing file" do
          user = users_class.create! posts_attributes: [{ document: Refile::FileDouble.new("foo") }]
          post = user.posts.first
          user.update! posts_attributes: [{ id: post.id, document: Refile::FileDouble.new("bar") }]

          post.reload
          expect(post.document.read).to eq("bar")
          expect(Refile.store.read(post.document.id)).to eq("bar")
        end
      end
    end
  end
end
