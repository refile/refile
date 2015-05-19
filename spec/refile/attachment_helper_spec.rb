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

  def with_setting(key, value)
    old = Refile.send(key)
    Refile.send("#{key}=", value)
    yield
  ensure
    Refile.send("#{key}=", old)
  end

  around { |example| with_setting(:secret_key, "xxxxxxxxxxx", &example) }

  describe "#attachment_image_tag" do
    let(:src) { attachment_image_tag(klass.new(document_id: "xxx"), :document)[/src="(\S+)"/, 1] }

    it "builds with path" do
      with_setting :host, nil do
        expect(src).to eq attachment_path
      end
    end

    it "builds with host" do
      expect(src).to eq "http://localhost:56120#{attachment_path}"
    end
  end
end
