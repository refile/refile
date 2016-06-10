require "refile/rails/attachment_helper"
require "refile/active_record_helper"
require "refile/attachment/active_record"
require "action_view"

describe Refile::AttachmentHelper do
  include Refile::AttachmentHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::FormHelper

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

  describe "#attachment_field" do
    context "with index given" do
      let(:html) { Capybara.string(attachment_field("post", :document, object: klass.new, index: 0)) }

      it "generates file and hidden inputs with identical names" do
        field_name = "post[0][document]"
        expect(html).to have_field(field_name, type: "file")
        expect(html).to have_selector(:css, "input[name='#{field_name}'][type=hidden]", visible: false, count: 1)
      end
    end
  end

  describe "#attachment_cache_field" do
    context "with index given" do
      let(:html) { Capybara.string(attachment_cache_field("post", :document, object: klass.new, index: 0)) }

      it "generates hidden input with given index" do
        expect(html).to have_selector(:css, "input[name='post[0][document]'][type=hidden]", visible: false)
      end
    end

    context "with reference given" do
      let(:html) { Capybara.string(attachment_cache_field("post", :document, object: klass.new, data: { reference: "xyz" })) }

      it "generates hidden input with given reference" do
        expect(html).to have_selector(:css, "input[data-reference=xyz]", visible: false)
      end
    end

    context "without reference given" do
      let(:html) { Capybara.string(attachment_cache_field("post", :document, object: klass.new)) }

      it "generates hidden input with a random reference" do
        expect(html).to have_selector(:css, "input[data-reference]", visible: false)
      end
    end
  end
end
