describe Refile::Download do
  context "without redirects" do
    it "fetches the file" do
      stub_request(:get, "http://www.example.com/dummy").to_return(
        status: 200,
        body: "dummy",
        headers: { "Content-Length" => 5, "Content-Type" => "text/plain" }
      )

      download = described_class.new("http://www.example.com/dummy")

      expect(download.io.read).to eq("dummy")
      expect(download.size).to eq(5)
      expect(download.content_type).to eq("text/plain")
      expect(download.original_filename).to eq("dummy")
    end
  end

  context "with redirects" do
    it "follows redirects and fetches the file" do
      stub_request(:get, "http://www.example.com/1").to_return(
        status: 302,
        headers: { "Location" => "http://www.example.com/2" }
      )

      stub_request(:get, "http://www.example.com/2").to_return(
        status: 200,
        body: "dummy",
        headers: { "Content-Length" => 5 }
      )

      download = described_class.new("http://www.example.com/1")

      expect(download.io.read).to eq("dummy")
      expect(download.size).to eq(5)
      expect(download.content_type).to eq("application/octet-stream")
      expect(download.original_filename).to eq("2")
    end

    it "handles redirect loops by throwing errors" do
      stub_request(:get, "http://www.example.com/loop").to_return(
        status: 302,
        headers: { "Location" => "http://www.example.com/loop" }
      )

      expect do
        described_class.new("http://www.example.com/loop")
      end.to raise_error(Refile::TooManyRedirects)
    end
  end
end
