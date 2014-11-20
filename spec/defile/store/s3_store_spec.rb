require "defile/store/s3_store"

if ENV["S3"]
  config = YAML.load_file("s3.yml").map { |k, v| [k.to_sym, v] }.to_h

  RSpec.describe Defile::Store::S3Store do
    let(:store) { Defile::Store::S3Store.new(**config) }

    it_behaves_like :store
  end
end
