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
    subject(:field) { attachment_field("post", :document, **field_options) }
    let(:field_options) { { object: klass.new } }
    let(:html) { Capybara.string(field) }
    let(:expected_field_name) { "post[0][document]" }
    let(:selector_css) { "input[name='#{expected_field_name}'][type=hidden]" }
    let(:input_css) { "input[name='post[document]'][type=hidden]" }

    context "with index given" do
      let(:field_options) { super().merge index: 0 }

      it "generates file and hidden inputs with identical names" do
        expect(html).to have_field(expected_field_name, type: "file")
        expect(html).to have_selector(:css, selector_css, visible: false, count: 1)
      end
    end

    context "when attacher value is blank" do
      let(:field_options) { super().merge object: klass.new(document: nil) }
      it "generates metadata hidden with disabled attribute" do
        expect(html.find(input_css, visible: false)["disabled"]).to eq "disabled"
      end
    end

    context "when attacher value is present" do
      let(:field_options) do
        super().merge object: klass.new(document: StringIO.new("New params"))
      end

      it "generates metadata input without disabled attribute" do
        expect(html.find(input_css, visible: false)["disabled"]).to be_nil
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
