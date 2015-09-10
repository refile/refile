require "refile/rails/attachment_helper"
require "refile/active_record_helper"
require "refile/attachment/active_record"
require "action_view"

describe Refile::AttachmentHelper do
  include Refile::AttachmentHelper
  include ActionView::Helpers::AssetTagHelper

  let(:klass) do
    Class.new(ActiveRecord::Base) do
      self.table_name = :posts

      def self.name
        "Post"
      end

      attachment :document
    end
  end
  let(:attachment_path) { "/attachments/00cc2633d08c6045485f1fae2cd6d4de20a5a159/store/xxx/document" }

  before do
    allow(Refile).to receive(:secret_key).and_return("xxxxxxxxxxx")
  end

  describe "#attachment_image_tag" do
    let(:src) { attachment_image_tag(klass.new(document_id: "xxx"), :document)[/src="(\S+)"/, 1] }

    it "builds with path" do
      allow(Refile).to receive(:app_host).and_return(nil)
      expect(src).to eq attachment_path
    end

    it "builds with host" do
      expect(src).to eq "http://localhost:56120#{attachment_path}"
    end
  end
end
