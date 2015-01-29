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
    it "returns 404 if backend is not marked as direct upload" do
      file = Rack::Test::UploadedFile.new(path("hello.txt"))
      post "/token/store", file: file

      expect(last_response.status).to eq(404)
      expect(last_response.content_type).to eq("text/plain;charset=utf-8")
      expect(last_response.body).to eq("not found")
    end

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
