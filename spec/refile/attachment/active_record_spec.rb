require "refile/active_record_helper"
require "refile/attachment/active_record"
require_relative "../support/accepts_attachments_for_shared_examples"

describe Refile::ActiveRecord::Attachment do
  let(:options) { {} }
  let(:required) { false }
  let(:klass) do
    opts = options
    req = required
    Class.new(ActiveRecord::Base) do
      self.table_name = :posts

      def self.name
        "Post"
      end

      attachment :document, **opts
      validates_presence_of :document, if: -> { req }
    end
  end

  describe "#valid?" do
    let(:options) { { type: :image, cache: :limited_cache } }

    context "extension validation" do
      let(:options) { { cache: :limited_cache, extension: %w[Png] } }

      context "with file" do
        let(:options) { { cache: :limited_cache, extension: %w[Png Gif] } }

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

        it "returns false and an error message when extension is invalid" do
          post = klass.new
          post.document = Refile::FileDouble.new("hello", "image.jpg")
          expect(post.valid?).to be_falsy
          expect(post.errors[:document]).to match_array([/not allowed to upload jpg.+Allowed types: Png[^,]?/])
        end

        it "returns false and an error message when extension is empty" do
          post = klass.new
          post.document = Refile::FileDouble.new("hello", "image")
          expect(post.valid?).to be_falsy
          expect(post.errors[:document]).to match_array([/not allowed to upload an empty.+Allowed types: Png[^,]?/])
        end
      end

      context "with metadata" do
        it "returns true when extension is included in list" do
          file = Refile.cache.upload(StringIO.new("hello"))
          post = klass.new
          post.document = { id: file.id, filename: "image.Png", size: file.size }.to_json
          expect(post.valid?).to be_truthy
          expect(post.errors[:document]).to be_empty
        end

        it "returns true when extension is included in list but chars are randomcase" do
          file = Refile.cache.upload(StringIO.new("hello"))
          post = klass.new
          post.document = { id: file.id, filename: "image.PNG", size: file.size }.to_json
          expect(post.valid?).to be_truthy
          expect(post.errors[:document]).to be_empty
        end

        it "returns false and an error message when extension is invalid" do
          file = Refile.cache.upload(StringIO.new("hello"))
          post = klass.new
          post.document = { id: file.id, filename: "image.gif", size: file.size }.to_json
          expect(post.valid?).to be_falsy
          expect(post.errors[:document]).to match_array([/not allowed to upload gif.+Allowed types: Png[^,]?/])
        end

        it "returns false and an error message when extension is empty" do
          file = Refile.cache.upload(StringIO.new("hello"))
          post = klass.new
          post.document = { id: file.id, filename: "image", size: file.size }.to_json
          expect(post.valid?).to be_falsy
          expect(post.errors[:document]).to match_array([/not allowed to upload an empty.+Allowed types: Png[^,]?/])
        end

        it "returns false when file size is zero" do
          file = Refile.cache.upload(StringIO.new("hello"))
          post = klass.new
          post.document = { id: file.id, filename: "image.Png" }.to_json
          expect(post.valid?).to be_falsy
          expect(post.errors[:document].length).to eq(1)
        end
      end

      context "extension as Proc" do
        context "Proc returns an array with extensions" do
          let(:options) { { cache: :limited_cache, extension: -> { ["gif"] } } }

          it "returns true when extension is included in list" do
            post = klass.new
            post.document = Refile::FileDouble.new("hello", "funny.gif")
            expect(post.valid?).to be_truthy
            expect(post.errors[:document]).to be_empty
          end
        end

        context "Proc returns nil" do
          let(:options) { { cache: :limited_cache, extension: -> {} } }

          it "returns true when extension is included in list" do
            post = klass.new
            post.document = Refile::FileDouble.new("hello", "funny.gif")
            expect(post.valid?).to be_falsey
            expect(post.errors[:document].length).to eq(1)
          end
        end
      end
    end

    context "with file" do
      it "returns true when no file is assigned" do
        post = klass.new
        expect(post.valid?).to be_truthy
        expect(post.errors[:document]).to be_empty
      end

      it "returns false and an error message when type is invalid" do
        post = klass.new
        post.document = Refile::FileDouble.new("hello", content_type: "text/plain")
        expect(post.valid?).to be_falsy
        expect(post.errors[:document]).to match_array(
          [%r{not allowed to upload text/plain.+Allowed types: image/jpeg, image/gif, and image/png[^,]?}]
        )
      end

      it "returns false and an error message when type is empty" do
        post = klass.new
        post.document = Refile::FileDouble.new("hello", content_type: "")
        expect(post.valid?).to be_falsy
        expect(post.errors[:document]).to match_array(
          [%r{not allowed to upload an empty.+Allowed types: image/jpeg, image/gif, and image/png[^,]?}]
        )
      end

      it "returns false and error messages when it has multiple errors" do
        post = klass.new
        post.document = Refile::FileDouble.new("h" * 200, content_type: "text/plain")
        expect(post.valid?).to be_falsy
        expect(post.errors[:document]).to match_array(
          [
            %r{not allowed to upload text/plain.+Allowed types: image/jpeg, image/gif, and image/png[^,]?},
            "is too large"
          ]
        )
      end

      it "returns true when type is valid" do
        post = klass.new
        post.document = Refile::FileDouble.new("hello", content_type: "image/png")
        expect(post.valid?).to be_truthy
        expect(post.errors[:document]).to be_empty
      end

      it "returns true when an encoding is appended to a valid type" do
        post = klass.new
        post.document = Refile::FileDouble.new("hello", content_type: "image/png;charset=UTF-8")
        expect(post.valid?).to be_truthy
        expect(post.errors[:document]).to be_empty
      end
    end

    context "when file is required" do
      let(:required) { true }
      let(:options) { {} }

      it "returns false without file" do
        post = klass.new
        expect(post.valid?).to be_falsy
      end

      it "returns true with file" do
        post = klass.new
        post.document = Refile::FileDouble.new("hello", "image.png")
        expect(post.valid?).to be_truthy
      end

      it "returns false when nil is assigned after a file" do
        post = klass.new
        post.document = Refile::FileDouble.new("hello", "image.png")
        post.document = nil
        expect(post.valid?).to be_falsy
      end
    end

    context "with metadata" do
      it "returns false when metadata doesn't have an id" do
        file = Refile.cache.upload(StringIO.new("hello"))
        post = klass.new
        post.document = { content_type: "text/png", size: file.size }.to_json
        expect(post.valid?).to be_falsy
        expect(post.errors[:document]).to match_array([%r{not allowed to upload text/png.+Allowed types: image/jpeg, image/gif, and image/png[^,]?}])
      end

      it "returns false and an error message when type is invalid" do
        file = Refile.cache.upload(StringIO.new("hello"))
        post = klass.new
        post.document = { id: file.id, content_type: "text/png", size: file.size }.to_json
        expect(post.valid?).to be_falsy
        expect(post.errors[:document]).to match_array([%r{not allowed to upload text/png.+Allowed types: image/jpeg, image/gif, and image/png[^,]?}])
      end

      it "returns false and an error message when type is empty" do
        file = Refile.cache.upload(StringIO.new("hello"))
        post = klass.new
        post.document = { id: file.id, content_type: "", size: file.size }.to_json
        expect(post.valid?).to be_falsy
        expect(post.errors[:document]).to match_array([%r{not allowed to upload an empty.+Allowed types: image/jpeg, image/gif, and image/png[^,]?}])
      end

      it "returns false when file size is zero" do
        file = Refile.cache.upload(StringIO.new(""))
        post = klass.new
        post.document = { id: file.id, content_type: "image/png", size: file.size }.to_json
        expect(post.valid?).to be_falsy
        expect(post.errors[:document].length).to eq(1)
      end

      it "returns true when type is valid" do
        file = Refile.cache.upload(StringIO.new("hello"))
        post = klass.new
        post.document = { id: file.id, content_type: "image/png", size: file.size }.to_json
        expect(post.valid?).to be_truthy
        expect(post.errors[:document]).to be_empty
      end

      it "returns true when an encoding is appended to a valid type" do
        file = Refile.cache.upload(StringIO.new("hello"))
        post = klass.new
        post.document = { id: file.id, content_type: "image/png;charset=UTF-8", size: file.size }.to_json
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

    it "replaces a attachment which was nil" do
      post = klass.new
      post.document = nil
      post.save

      post.document = Refile::FileDouble.new("hello")
      post.save

      expect(Refile.store.read(post.document.id)).to eq("hello")
      expect(post.document).not_to be_nil
    end
  end

  describe "#destroy" do
    context "default behaviour" do
      it "removes the stored file" do
        post = klass.new
        post.document = Refile::FileDouble.new("hello")
        post.save
        file = post.document
        post.destroy
        expect(file.exists?).to be_falsy
      end
    end

    context "with destroy: true" do
      let(:options) { { destroy: true } }

      it "removes the stored file" do
        post = klass.new
        post.document = Refile::FileDouble.new("hello")
        post.save
        file = post.document
        post.destroy
        expect(file.exists?).to be_falsy
      end
    end

    context "with destroy: false" do
      let(:options) { { destroy: false } }

      it "does not remove the stored file" do
        post = klass.new
        post.document = Refile::FileDouble.new("hello")
        post.save
        file = post.document
        post.destroy
        expect(file.exists?).to be_truthy
      end
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

        attachment :file, type: :image
      end
    end

    let(:post) { post_class.new }

    it_should_behave_like "accepts_attachments_for"

    it "shouldn't raise error on setter method_missing" do
      expect { post.creator = nil }.to_not raise_error(ArgumentError)
    end

    context "when a wrong association is called" do
      let(:wrong_method) { "files" }
      let(:wrong_association_message) do
        "wrong association name #{wrong_method}, use like this documents_files"
      end

      it "returns a friendly error message" do
        expect { post.send(wrong_method) }.to raise_error(wrong_association_message)
      end

      it "return method missing" do
        expect { post.foo }.to_not raise_error(wrong_association_message)
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

          user.update!(post_attributes: { id: post.id, remove_document: true })

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

          user.update!(posts_attributes: { id: post.id, remove_document: true })

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

  context "when assigned to an attribute that does not track changes" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = :posts

        attachment :not_trackable_attribute
      end
    end

    it "assigns the file to the attribute" do
      post = klass.new
      post.not_trackable_attribute = Refile::FileDouble.new("foo")
      expect(post.not_trackable_attribute.read).to eq("foo")
    end
  end
end
