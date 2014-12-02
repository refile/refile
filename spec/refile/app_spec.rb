require "rack/test"

describe Refile::App do
  include Rack::Test::Methods

  def app
    Refile::App.new
  end

  describe "GET /:backend/:id/:filename" do
    it "returns a stored file" do
      file = Refile.store.upload(StringIO.new("hello"))

      get "/store/#{file.id}/hello"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("hello")
    end

    it "returns a 404 if the file doesn't exist" do
      file = Refile.store.upload(StringIO.new("hello"))

      get "/store/doesnotexist/hello"

      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq("not found")
    end

    it "returns a 404 if the backend doesn't exist" do
      file = Refile.store.upload(StringIO.new("hello"))

      get "/doesnotexist/#{file.id}/hello"

      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq("not found")
    end

    context "with allow origin" do
      def app
        Refile::App.new(allow_origin: "example.com")
      end

      it "sets CORS header" do
        file = Refile.store.upload(StringIO.new("hello"))

        get "/store/#{file.id}/hello"

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq("hello")
        expect(last_response.headers["Access-Control-Allow-Origin"]).to eq("example.com")
      end
    end

    it "returns a 404 for non get requests" do
      file = Refile.store.upload(StringIO.new("hello"))

      post "/store/#{file.id}/hello"

      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq("not found")
    end
  end

  describe "GET /:backend/:processor/:id/:filename" do
    it "returns 404 if processor does not exist" do
      file = Refile.store.upload(StringIO.new("hello"))

      get "/store/doesnotexist/#{file.id}/hello"

      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq("not found")
    end

    it "applies block processor to file" do
      file = Refile.store.upload(StringIO.new("hello"))

      get "/store/reverse/#{file.id}/hello"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("olleh")
    end

    it "applies object processor to file" do
      file = Refile.store.upload(StringIO.new("hello"))

      get "/store/upcase/#{file.id}/hello"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("HELLO")
    end

    it "applies processor with arguments" do
      file = Refile.store.upload(StringIO.new("hello"))

      get "/store/concat/foo/bar/baz/#{file.id}/hello"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("hellofoobarbaz")
    end

    it "applies processor with format" do
      file = Refile.store.upload(StringIO.new("hello"))

      get "/store/convert_case/#{file.id}/hello.up"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("HELLO")
    end
  end

  describe "POST /:backend" do
    it "returns 404 if backend is not marked as direct upload" do
      file = Rack::Test::UploadedFile.new(path("hello.txt"))
      post "/store", file: file

      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq("not found")
    end

    it "uploads a file for direct upload backends" do
      file = Rack::Test::UploadedFile.new(path("hello.txt"))
      post "/cache", file: file

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)["id"]).not_to be_empty
    end
  end

  it "returns a 404 if id not given" do
    get "/store"

    expect(last_response.status).to eq(404)
    expect(last_response.body).to eq("not found")
  end

  it "returns a 404 for root" do
    get "/"

    expect(last_response.status).to eq(404)
    expect(last_response.body).to eq("not found")
  end
end

