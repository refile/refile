if ENV["S3"]
  require "defile/backend/s3"

  config = YAML.load_file("s3.yml").map { |k, v| [k.to_sym, v] }.to_h

  RSpec.describe Defile::Backend::S3 do
    let(:backend) { Defile::Backend::S3.new(max_size: 100, **config) }

    it_behaves_like :backend
  end
end
