RSpec.shared_examples "accepts_attachments_for" do
  describe "#:association_:name=" do
    it "builds records from assigned files" do
      post.documents_files = [
        Refile::FileDouble.new("hello", content_type: "image/jpeg"),
        Refile::FileDouble.new("world", content_type: "image/jpeg")
      ]
      post.save!

      expect(post.documents.size).to eq(2)
      expect(post.documents[0].file.read).to eq("hello")
      expect(post.documents[1].file.read).to eq("world")
    end

    it "clears previously assigned files" do
      post.documents_files = [
        Refile::FileDouble.new("hello", content_type: "image/jpeg"),
        Refile::FileDouble.new("world", content_type: "image/jpeg")
      ]
      post.save!
      post.update! documents_files: [
        Refile::FileDouble.new("foo", content_type: "image/jpeg")
      ]

      expect(post.documents[0].file.read).to eq("foo")
      expect(post.documents.size).to eq(1)
    end

    it "ignores nil assigned files" do
      post.documents_files = [
        Refile::FileDouble.new("hello", content_type: "image/jpeg"),
        nil,
        nil
      ]
      post.save!

      expect(post.documents.size).to eq(1)
      expect(post.documents[0].file.read).to eq("hello")
    end

    it "builds records from cache" do
      post.documents_files = [
        [
          {
            id: Refile.cache.upload(Refile::FileDouble.new("hello")).id,
            filename: "some.jpg",
            content_type: "image/jpeg",
            size: 1234
          },
          {
            id: Refile.cache.upload(Refile::FileDouble.new("world")).id,
            filename: "some.jpg",
            content_type: "image/jpeg",
            size: 1234
          }
        ].to_json
      ]
      post.save!

      expect(post.documents.size).to eq(2)
      expect(post.documents[0].file.read).to eq("hello")
      expect(post.documents[1].file.read).to eq("world")
    end

    it "prefers uploaded files over cache when both are present" do
      post.documents_files = [
        [
          {
            id: Refile.cache.upload(Refile::FileDouble.new("moo")).id,
            filename: "some.jpg",
            content_type: "image/jpeg",
            size: 1234
          }
        ].to_json,
        Refile::FileDouble.new("hello", content_type: "image/jpeg"),
        Refile::FileDouble.new("world", content_type: "image/jpeg")
      ]
      post.save!

      expect(post.documents.size).to eq(2)
      expect(post.documents[0].file.read).to eq("hello")
      expect(post.documents[1].file.read).to eq("world")
    end

    it "ignores empty caches" do
      post.documents_files = [
        [
          {
            id: Refile.cache.upload(Refile::FileDouble.new("moo")).id,
            filename: "some.jpg",
            content_type: "image/jpeg",
            size: 1234
          },
          {},
          {}
        ].to_json
      ]
      post.save!

      expect(post.documents.size).to eq(1)
      expect(post.documents[0].file.read).to eq("moo")
    end

    it "ignores caches with malformed json" do
      post.documents_files = [
        "[{id: 'this is a ruby hash'}]"
      ]

      expect(post.documents.size).to be_zero
    end

    context "with append: true" do
      let(:options) { { append: true } }

      it "appends to previously assigned files" do
        post.documents_files = [
          Refile::FileDouble.new("hello", content_type: "image/jpeg"),
          Refile::FileDouble.new("world", content_type: "image/jpeg")
        ]
        post.save!
        post.update! documents_files: [
          Refile::FileDouble.new("foo", content_type: "image/jpeg")
        ]

        expect(post.documents.size).to eq(3)
        expect(post.documents[0].file.read).to eq("hello")
        expect(post.documents[1].file.read).to eq("world")
        expect(post.documents[2].file.read).to eq("foo")
      end

      it "appends to previously assigned files with cached files" do
        post.documents_files = [
          Refile::FileDouble.new("hello", content_type: "image/jpeg"),
          Refile::FileDouble.new("world", content_type: "image/jpeg")
        ]
        post.save!
        post.update! documents_files: [
          [{
            id: Refile.cache.upload(Refile::FileDouble.new("hello world")).id,
            filename: "some.jpg",
            content_type: "image/jpeg",
            size: 1234
          }].to_json
        ]

        expect(post.documents.size).to eq(3)
        expect(post.documents[0].file.read).to eq("hello")
        expect(post.documents[1].file.read).to eq("world")
        expect(post.documents[2].file.read).to eq("hello world")
      end

      it "appends to previously cached files with cached files" do
        post.documents_files = [
          [
            {
              id: Refile.cache.upload(Refile::FileDouble.new("moo")).id,
              filename: "some1.jpg",
              content_type: "image/jpeg",
              size: 123
            }
          ].to_json
        ]
        post.documents_files = [
          [
            {
              id: Refile.cache.upload(Refile::FileDouble.new("hello")).id,
              filename: "some2.jpg",
              content_type: "image/jpeg",
              size: 1234
            }
          ].to_json
        ]
        post.save!

        expect(post.documents.size).to eq(2)
        expect(post.documents[0].file.read).to eq("moo")
        expect(post.documents[1].file.read).to eq("hello")
      end
    end
  end

  describe "#:association_:name_data" do
    it "returns metadata for all files" do
      post.documents_files = [
        nil,
        Refile::FileDouble.new("hello", content_type: "image/jpeg"),
        Refile::FileDouble.new("world", content_type: "image/jpeg")
      ]
      data = post.documents_files_data

      expect(data.size).to eq(2)
      expect(Refile.cache.read(data[0][:id])).to eq("hello")
      expect(Refile.cache.read(data[1][:id])).to eq("world")
    end

    context "when there are invalid files" do
      it "only returns metadata for valid files " do
        invalid_file = Refile::FileDouble.new("world", content_type: "text/plain")

        post.documents_files = [invalid_file]
        data = post.documents_files_data

        expect(data).to be_nil
      end
    end
  end

  describe "#:association_:name" do
    it "builds records from assigned files" do
      post.documents_files = [
        Refile::FileDouble.new("hello", content_type: "image/jpeg"),
        Refile::FileDouble.new("world", content_type: "image/jpeg")
      ]

      expect(post.documents_files.size).to eq(2)
      expect(post.documents_files[0].read).to eq("hello")
      expect(post.documents_files[1].read).to eq("world")
    end
  end

  describe "#:association_:name_attachment_definition" do
    it "returns attachment definition" do
      post.documents_files = [
        Refile::FileDouble.new("hello", content_type: "image/jpeg")
      ]

      definition = post.documents_files_attachment_definition
      expect(definition).to be_a Refile::AttachmentDefinition
      expect(definition.name).to eq(:file)
    end
  end
end
