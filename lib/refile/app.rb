require "json"
require "sinatra/base"
module Refile
  class App < Sinatra::Base

    configure do
      set :show_exceptions, false
      set :raise_errors, false
      set :sessions, false
      set :logging, false
      set :dump_errors, false
    end

    before do
      content_type ::File.extname(request.path), default: 'application/octet-stream'
      if Refile.app_allowed_origin
        response["Access-Control-Allow-Origin"] = Refile.app_allowed_origin
        response["Access-Control-Allow-Headers"] = request.env["HTTP_ACCESS_CONTROL_REQUEST_HEADERS"].to_s
        response["Access-Control-Allow-Method"] = request.env["HTTP_ACCESS_CONTROL_REQUEST_METHOD"].to_s
      end
    end

    get "/:backend/:id/:filename" do
      ensure_file do |file|
        stream_file(file)
      end
    end

    get "/:backend/:processor/:id/:file_basename.:extension" do
      ensure_file_and_processor do |file, processor|
        stream_file processor.call(file, format: params[:extension])
      end
    end

    get "/:backend/:processor/:id/:filename" do
      ensure_file_and_processor do |file, processor|
        stream_file processor.call(file)
      end
    end

    get "/:backend/:processor/*/:id/:file_basename.:extension" do
      ensure_file_and_processor do |file, processor|
        stream_file processor.call(file, *params[:splat].first.split("/"), format: params[:extension])
      end
    end

    get "/:backend/:processor/*/:id/:filename" do
      ensure_file_and_processor do |file, processor|
        stream_file processor.call(file, *params[:splat].first.split("/"))
      end
    end

    options "/:backend" do
      ""
    end

    post "/:backend" do
      backend = Refile.backends[params[:backend]]
      halt 404 unless backend && Refile.direct_upload.include?(params[:backend])
      tempfile = request.params.fetch("file").fetch(:tempfile)
      file = backend.upload(tempfile)
      content_type :json
      { id: file.id }.to_json
    end

    not_found do
      content_type :text
      "not found"
    end

    error do |error_thrown|
      log_error("Error -> #{error_thrown}")
      error_thrown.backtrace.each do |line|
        log_error(line)
      end
      content_type :text
      "error"
    end

    private

    def logger
      Refile.app_logger
    end

    def stream_file(file)
      stream do |out|
        file.each do |chunk|
          out << chunk
        end
      end
    end

    def ensure_file_and_processor
      ensure_processor do |processor|
        ensure_file do |file|
          yield file, processor
        end
      end
    end

    def ensure_file
      backend = Refile.backends[params[:backend]]
      unless backend
        log_error("Could not find backend: #{params[:backend]}")
        halt 404
      end
      file = backend.get(params[:id])
      unless file.exists?
        log_error("Could not find attachment by id: #{params[:id]}")
        halt 404
      end
      yield file
    end

    def ensure_processor
      processor = Refile.processors[params[:processor]]
      unless processor
        log_error("Could not find processor: #{params[:processor]}")
        halt 404
      end
      yield processor
    end

    def log_error(message)
      logger.error "#{self.class.name}: #{message}"
    end
  end
end
