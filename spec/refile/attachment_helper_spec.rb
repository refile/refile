require "refile/rails/attachment_helper"
require "refile/active_record_helper"
require "refile/attachment/active_record"
require "action_view"
require "capybara/rspec"

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
    subject(:field) { attachment_field("post", :document, field_options) }
    let(:field_options) { { object: klass.new } }

    let(:html) { Capybara.string(field) }

    context "with index given" do
      let(:field_options) { super().merge index: 0 }

      it "generates file input and metadata input with identical names" do
        expected_field_name = "post[0][document]"
        expect(html).to have_field(expected_field_name, type: "file")
        expect(html).to have_selector(:css, "input[name='#{expected_field_name}'][type=text]", visible: false)
      end
    end

    context "when attacher value is blank" do
      let(:field_options) { super().merge object: klass.new(document: nil) }

      it "generates metadata input with disabled attribute" do
        expect(html.find("input[name='post[document]'][type=text]", visible: false)["disabled"]).to eq "disabled"
      end
    end

    context "when attacher value is present" do
      let(:field_options) { super().merge object: klass.new(document: StringIO.new("aaa")) }

      it "generates metadata input without disabled attribute" do
        expect(html.find("input[name='post[document]'][type=text]", visible: false)["disabled"]).to be_nil
      end
    end
  end
end
