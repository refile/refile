require "refile/custom_logger"

describe Refile::CustomLogger do
  let(:rack_app) do
    ->(_) { [200, {}, ["Success"]] }
  end
  let(:io) { StringIO.new }
  let(:env) do
    { "QUERY_STRING" => "",
      "REQUEST_METHOD" => "POST",
      "PATH_INFO" => "/" }
  end

  let(:expected_format) { %r{Prefix: \[[^\]]+\] POST "/" 200 \d+\.\d+ms\n\n$} }

  it "uses a dynamic logger" do
    _, _, body = described_class.new(rack_app, "Prefix", -> { Logger.new(io) }).call(env)
    body.close
    expect(io.tap(&:rewind).read).to match(expected_format)
  end
end
