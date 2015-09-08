require "rack/test"

describe Refile::App do
  include Rack::Test::Methods

  def app
    Refile::App.new
  end

  before do
    allow(Refile).to receive(:token).and_return("token")
  end

  describe "GET /:backend/:id/:filename" do
    it "returns a stored file" do
      file = Refile.store.upload(StringIO.new("hello"))

      get "/token/store/#{file.id}/hello"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("hello")
    end

    it "sets appropriate content type from extension" do
      file = Refile.store.upload(StringIO.new("hello"))

      get "/token/store/#{file.id}/hello.html"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("hello")
      expect(last_response.headers["Content-Type"]).to include("text/html")
    end

    it "returns a 404 if the file doesn't exist" do
      Refile.store.upload(StringIO.new("hello"))

      get "/token/store/doesnotexist/hello"

      expect(last_response.status).to eq(404)
      expect(last_response.content_type).to eq("text/plain;charset=utf-8")
      expect(last_response.body).to eq("not found")
    end

    it "returns a 404 if the backend doesn't exist" do
      file = Refile.store.upload(StringIO.new("hello"))

      get "/token/doesnotexist/#{file.id}/hello"

      expect(last_response.status).to eq(404)
      expect(last_response.content_type).to eq("text/plain;charset=utf-8")
      expect(last_response.body).to eq("not found")
    end

    context "with allow origin" do
      before(:each) do
        allow(Refile).to receive(:allow_origin).and_return("example.com")
      end

      it "sets CORS header" do
        file = Refile.store.upload(StringIO.new("hello"))

        get "/token/store/#{file.id}/hello"

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq("hello")
        expect(last_response.headers["Access-Control-Allow-Origin"]).to eq("example.com")
      end
    end

    it "returns a 200 for head requests" do
      file = Refile.store.upload(StringIO.new("hello"))

      head "/token/store/#{file.id}/hello"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to be_empty
    end

    it "returns a 404 for head requests if the file doesn't exist" do
      Refile.store.upload(StringIO.new("hello"))

      head "/token/store/doesnotexist/hello"

      expect(last_response.status).to eq(404)
      expect(last_response.body).to be_empty
    end

    it "returns a 404 for non get requests" do
      file = Refile.store.upload(StringIO.new("hello"))

      post "/token/store/#{file.id}/hello"

      expect(last_response.status).to eq(404)
      expect(last_response.content_type).to eq("text/plain;charset=utf-8")
      expect(last_response.body).to eq("not found")
    end

    context "verification" do
      before do
        allow(Refile).to receive(:token).and_call_original
      end

      it "accepts valid token" do
        file = Refile.store.upload(StringIO.new("hello"))
        token = Refile.token("/store/#{file.id}/hello")

        get "/#{token}/store/#{file.id}/hello"

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq("hello")
      end

      it "returns a 403 for unsigned get requests" do
        file = Refile.store.upload(StringIO.new("hello"))

        get "/eviltoken/store/#{file.id}/hello"

        expect(last_response.status).to eq(403)
        expect(last_response.body).to eq("forbidden")
      end

      it "does not retrieve nor process files for unauthenticated requests" do
        file = Refile.store.upload(StringIO.new("hello"))

        expect(Refile.store).not_to receive(:get)
        get "/eviltoken/store/#{file.id}/hello"

        expect(last_response.status).to eq(403)
        expect(last_response.body).to eq("forbidden")
      end
    end

    context "when unrestricted" do
      before do
        allow(Refile).to receive(:allow_downloads_from).and_return(:all)
      end

      it "gets signatures from all backends" do
        file = Refile.store.upload(StringIO.new("hello"))
        get "/token/store/#{file.id}/test.txt"
        expect(last_response.status).to eq(200)
      end
    end

    context "when restricted" do
      before do
        allow(Refile).to receive(:allow_downloads_from).and_return(["store"])
      end

      it "gets signatures from allowed backend" do
        file = Refile.store.upload(StringIO.new("hello"))
        get "/token/store/#{file.id}/test.txt"
        expect(last_response.status).to eq(200)
      end

      it "returns 404 if backend is not allowed" do
        file = Refile.store.upload(StringIO.new("hello"))
        get "/token/cache/#{file.id}/test.txt"
        expect(last_response.status).to eq(404)
      end
    end
  end

  describe "GET /:backend/:processor/:id/:filename" do
    it "returns 404 if processor does not exist" do
      file = Refile.store.upload(StringIO.new("hello"))

      get "/token/store/doesnotexist/#{file.id}/hello"

      expect(last_response.status).to eq(404)
      expect(last_response.content_type).to eq("text/plain;charset=utf-8")
      expect(last_response.body).to eq("not found")
    end

    it "applies block processor to file" do
      file = Refile.store.upload(StringIO.new("hello"))

      get "/token/store/reverse/#{file.id}/hello"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("olleh")
    end

    it "applies object processor to file" do
      file = Refile.store.upload(StringIO.new("hello"))

      get "/token/store/upcase/#{file.id}/hello"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("HELLO")
    end

    it "applies processor with arguments" do
      file = Refile.store.upload(StringIO.new("hello"))

      get "/token/store/concat/foo/bar/baz/#{file.id}/hello"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("hellofoobarbaz")
    end

    it "applies processor with format" do
      file = Refile.store.upload(StringIO.new("hello"))

      get "/token/store/convert_case/#{file.id}/hello.up"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("HELLO")
    end

    it "returns a 403 for unsigned request" do
      file = Refile.store.upload(StringIO.new("hello"))

      get "/eviltoken/store/reverse/#{file.id}/hello"

      expect(last_response.status).to eq(403)
      expect(last_response.body).to eq("forbidden")
    end
  end

  describe "POST /:backend" do
    it "uploads a file for direct upload backends" do
      file = Rack::Test::UploadedFile.new(path("hello.txt"))
      post "/cache", file: file

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)["id"]).not_to be_empty
    end

    it "does not require signed request param to upload" do
      allow(Refile).to receive(:secret_key).and_return("abcd1234")

      file = Rack::Test::UploadedFile.new(path("hello.txt"))
      post "/cache", file: file

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)["id"]).not_to be_empty
    end

    context "when unrestricted" do
      before do
        allow(Refile).to receive(:allow_uploads_to).and_return(:all)
      end

      it "allows uploads to all backends" do
        post "/store", file: Rack::Test::UploadedFile.new(path("hello.txt"))
        expect(last_response.status).to eq(200)
      end
    end

    context "when restricted" do
      before do
        allow(Refile).to receive(:allow_uploads_to).and_return(["cache"])
      end

      it "allows uploads to allowed backends" do
        post "/cache", file: Rack::Test::UploadedFile.new(path("hello.txt"))
        expect(last_response.status).to eq(200)
      end

      it "returns 404 if backend is not allowed" do
        post "/store", file: Rack::Test::UploadedFile.new(path("hello.txt"))
        expect(last_response.status).to eq(404)
      end
    end

    context "when file is invalid" do
      before do
        allow(Refile).to receive(:allow_uploads_to).and_return(:all)
      end

      context "when file is too big" do
        before do
          backend = double
          allow(backend).to receive(:upload).with(anything).and_raise(Refile::InvalidMaxSize)
          allow_any_instance_of(Refile::App).to receive(:backend).and_return(backend)
        end

        it "returns 413 if file is too big" do
          post "/store_max_size", file: Rack::Test::UploadedFile.new(path("hello.txt"))
          expect(last_response.status).to eq(413)
        end
      end

      context "when other unexpected exception happens" do
        before do
          backend = double
          allow(backend).to receive(:upload).with(anything).and_raise(Refile::InvalidFile)
          allow_any_instance_of(Refile::App).to receive(:backend).and_return(backend)
        end

        it "returns 400 if file is too big" do
          post "/store_max_size", file: Rack::Test::UploadedFile.new(path("hello.txt"))
          expect(last_response.status).to eq(400)
        end
      end
    end
  end

  describe "GET /:backend/presign" do
    it "returns presign signature" do
      get "/limited_cache/presign"

      expect(last_response.status).to eq(200)
      result = JSON.parse(last_response.body)
      expect(result["id"]).not_to be_empty
      expect(result["url"]).to eq("/presigned/posts/upload")
      expect(result["as"]).to eq("file")
    end

    context "when unrestricted" do
      before do
        allow(Refile).to receive(:allow_uploads_to).and_return(:all)
      end

      it "gets signatures from all backends" do
        get "/limited_cache/presign"
        expect(last_response.status).to eq(200)
      end
    end

    context "when restricted" do
      before do
        allow(Refile).to receive(:allow_uploads_to).and_return(["limited_cache"])
      end

      it "gets signatures from allowed backend" do
        get "/limited_cache/presign"
        expect(last_response.status).to eq(200)
      end

      it "returns 404 if backend is not allowed" do
        get "/store/presign"
        expect(last_response.status).to eq(404)
      end
    end
  end

  it "returns a 404 if id not given" do
    get "/token/store"

    expect(last_response.status).to eq(404)
    expect(last_response.content_type).to eq("text/plain;charset=utf-8")
    expect(last_response.body).to eq("not found")
  end

  it "returns a 404 for root" do
    get "/"

    expect(last_response.status).to eq(404)
    expect(last_response.content_type).to eq("text/plain;charset=utf-8")
    expect(last_response.body).to eq("not found")
  end
end
