if ENV["S3"]
  require "refile/backend/s3"

  config = YAML.load_file("s3.yml").map { |k, v| [k.to_sym, v] }.to_h

  RSpec.describe Refile::Backend::S3 do
    let(:backend) { Refile::Backend::S3.new(max_size: 100, **config) }

    it_behaves_like :backend
  end
end
