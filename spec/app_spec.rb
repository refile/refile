require "rack/test"

describe Defile::App do
  include Rack::Test::Methods

  def app
    Defile::App.new
  end

  describe "/:backend/:id" do
    it "returns a stored file" do
      file = Defile.store.upload(StringIO.new("hello"))

      get "/store/#{file.id}"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("hello")
    end

    it "returns a 404 if the file doesn't exist" do
      file = Defile.store.upload(StringIO.new("hello"))

      get "/store/doesnotexist"

      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq("not found")
    end

    it "returns a 404 if the backend doesn't exist" do
      file = Defile.store.upload(StringIO.new("hello"))

      get "/doesnotexist/#{file.id}"

      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq("not found")
    end

    context "with allow origin" do
      def app
        Defile::App.new(allow_origin: "example.com")
      end

      it "sets CORS header" do
        file = Defile.store.upload(StringIO.new("hello"))

        get "/store/#{file.id}"

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq("hello")
        expect(last_response.headers["Access-Control-Allow-Origin"]).to eq("example.com")
      end
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

  it "returns a 404 for non get requests" do
    file = Defile.store.upload(StringIO.new("hello"))

    post "/store/#{file.id}"

    expect(last_response.status).to eq(404)
    expect(last_response.body).to eq("not found")
  end
end

