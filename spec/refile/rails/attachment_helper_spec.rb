require 'refile'
require 'active_support/inflector'
require 'refile/rails/attachment_helper'
describe Refile::AttachmentHelper do
  describe '#attachment_url' do
    let(:view) { Struct.new(:main_app, :request).new(main_app, request) }
    let(:main_app) { double :main_app, refile_app_path: 'attachments' }
    let(:request) { double :request, base_url: 'http://www.example.com' }
    let(:record) { double name, image: file }
    let(:name) { :image }
    let(:file) { double :file, backend: backend, id: '123abc' }
    let(:backend) { double :backend }
    before do
      view.extend(Refile::AttachmentHelper)
      Refile.backends['test_backend'] = backend
    end
    after do
      Refile.backends.delete('test_backend')
    end

    context 'with a host passed in' do
      let(:host) { '//cdn.example.com' }
      let(:expected_url) { '//cdn.example.com/attachments/test_backend/fill/300/300/123abc/test.jpg' }

      it 'creates the expected url' do
        expect(view.attachment_url(record, name, 'fill', 300, 300, filename: 'test', format: 'jpg', host: host)).to eq expected_url
      end
    end

    context 'with no host passed in, but Refile.host set' do
      let(:expected_url) { '//cdn.example.com/attachments/test_backend/fill/300/300/123abc/test.jpg' }
      before do
        @original_host = Refile.host
        Refile.host = '//cdn.example.com'
      end
      after do
        Refile.host = @original_host
      end

      it 'creates the expected url' do
        expect(view.attachment_url(record, name, 'fill', 300, 300, filename: 'test', format: 'jpg')).to eq expected_url
      end
    end

    context 'with no host passed in, and no Refile.host set' do
      let(:expected_url) { 'http://www.example.com/attachments/test_backend/fill/300/300/123abc/test.jpg' }
      before do
        @original_host = Refile.host
        Refile.host = nil
      end
      after do
        Refile.host = @original_host
      end

      it 'creates the expected url' do
        expect(view.attachment_url(record, name, 'fill', 300, 300, filename: 'test', format: 'jpg')).to eq expected_url
      end
    end
  end
end
