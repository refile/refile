require "rack/test"

Defile.processor(:reverse) do |file|
  StringIO.new(file.read.reverse)
end

Defile.processor(:upcase, proc { |file| StringIO.new(file.read.upcase) })

Defile.processor(:concat) do |file, *words|
  content = File.read(file.download.path)
  tempfile = Tempfile.new("concat")
  tempfile.write(content)
  words.each do |word|
    tempfile.write(word)
  end
  tempfile.close
  File.open(tempfile.path, "r")
end

describe Defile::App do
  include Rack::Test::Methods

  def app
    Defile::App.new
  end

  describe "/:backend/:id/:filename" do
    it "returns a stored file" do
      file = Defile.store.upload(StringIO.new("hello"))

      get "/store/#{file.id}/hello"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("hello")
    end

    it "returns a 404 if the file doesn't exist" do
      file = Defile.store.upload(StringIO.new("hello"))

      get "/store/doesnotexist/hello"

      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq("not found")
    end

    it "returns a 404 if the backend doesn't exist" do
      file = Defile.store.upload(StringIO.new("hello"))

      get "/doesnotexist/#{file.id}/hello"

      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq("not found")
    end

    context "with allow origin" do
      def app
        Defile::App.new(allow_origin: "example.com")
      end

      it "sets CORS header" do
        file = Defile.store.upload(StringIO.new("hello"))

        get "/store/#{file.id}/hello"

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq("hello")
        expect(last_response.headers["Access-Control-Allow-Origin"]).to eq("example.com")
      end
    end
  end

  describe "/:backend/:id/:processor" do
    it "returns 404 if processor does not exist" do
      file = Defile.store.upload(StringIO.new("hello"))

      get "/store/doesnotexist/#{file.id}/hello"

      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq("not found")
    end

    it "applies block processor to file" do
      file = Defile.store.upload(StringIO.new("hello"))

      get "/store/reverse/#{file.id}/hello"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("olleh")
    end

    it "applies object processor to file" do
      file = Defile.store.upload(StringIO.new("hello"))

      get "/store/upcase/#{file.id}/hello"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("HELLO")
    end

    it "applies processor with arguments" do
      file = Defile.store.upload(StringIO.new("hello"))

      get "/store/concat/foo/bar/baz/#{file.id}/hello"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("hellofoobarbaz")
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

    post "/store/#{file.id}/hello"

    expect(last_response.status).to eq(404)
    expect(last_response.body).to eq("not found")
  end
end

