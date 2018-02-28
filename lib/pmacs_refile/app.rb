require "json"
require "sinatra/base"
require "tempfile"

module PmacsRefile
  # A Rack application which can be mounted or run on its own.
  #
  # @example mounted in Rails
  #   Rails.application.routes.draw do
  #     mount PmacsRefile::App.new, at: "attachments", as: :refile_app
  #   end
  #
  # @example as standalone app
  #   require "refile"
  #
  #   run PmacsRefile::App.new
  class App < Sinatra::Base
    configure do
      set :show_exceptions, false
      set :raise_errors, false
      set :sessions, false
      set :logging, false
      set :dump_errors, false
      use CustomLogger, "PmacsRefile::App", proc { PmacsRefile.logger }
    end

    before do
      if PmacsRefile.allow_origin
        response["Access-Control-Allow-Origin"] = PmacsRefile.allow_origin
        response["Access-Control-Allow-Headers"] = request.env["HTTP_ACCESS_CONTROL_REQUEST_HEADERS"].to_s
        response["Access-Control-Allow-Method"] = request.env["HTTP_ACCESS_CONTROL_REQUEST_METHOD"].to_s
      end
    end

    # This will match all token authenticated requests
    before "/:token/:backend/*" do
      halt 403 unless verified?
    end

    get "/:token/:backend/:id/:filename" do
      halt 404 unless download_allowed?
      stream_file file
    end

    get "/:token/:backend/:processor/:id/:file_basename.:extension" do
      halt 404 unless download_allowed?
      stream_file processor.call(file, format: params[:extension])
    end

    get "/:token/:backend/:processor/:id/:filename" do
      halt 404 unless download_allowed?
      stream_file processor.call(file)
    end

    get "/:token/:backend/:processor/*/:id/:file_basename.:extension" do
      halt 404 unless download_allowed?
      stream_file processor.call(file, *params[:splat].first.split("/"), format: params[:extension])
    end

    get "/:token/:backend/:processor/*/:id/:filename" do
      halt 404 unless download_allowed?
      stream_file processor.call(file, *params[:splat].first.split("/"))
    end

    options "/:backend" do
      ""
    end

    post "/:backend" do
      halt 404 unless upload_allowed?
      tempfile = request.params.fetch("file").fetch(:tempfile)
      filename = request.params.fetch("file").fetch(:filename)
      file = backend.upload(tempfile)
      url = PmacsRefile.file_url(file, filename: filename)
      content_type :json
      { id: file.id, url: url }.to_json
    end

    get "/:backend/presign" do
      halt 404 unless upload_allowed?
      content_type :json
      backend.presign.to_json
    end

    not_found do
      content_type :text
      "not found"
    end

    error 403 do
      content_type :text
      "forbidden"
    end

    error PmacsRefile::InvalidFile do
      status 400
      "Upload failure error"
    end

    error PmacsRefile::InvalidMaxSize do
      status 413
      "Upload failure error"
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

    def download_allowed?
      PmacsRefile.allow_downloads_from == :all or PmacsRefile.allow_downloads_from.include?(params[:backend])
    end

    def upload_allowed?
      PmacsRefile.allow_uploads_to == :all or PmacsRefile.allow_uploads_to.include?(params[:backend])
    end

    def logger
      PmacsRefile.logger
    end

    def stream_file(file)
      expires PmacsRefile.content_max_age, :public

      if file.respond_to?(:path)
        path = file.path
      else
        path = Dir::Tmpname.create(params[:id]) {}
        IO.copy_stream file, path
      end

      filename = Rack::Utils.unescape(request.path.split("/").last)
      disposition = force_download?(params) ? "attachment" : "inline"

      send_file path, filename: filename, disposition: disposition, type: ::File.extname(filename)
    end

    def backend
      PmacsRefile.backends.fetch(params[:backend]) do |name|
        log_error("Could not find backend: #{name}")
        halt 404
      end
    end

    def file
      file = backend.get(params[:id])
      unless file.exists?
        log_error("Could not find attachment by id: #{params[:id]}")
        halt 404
      end
      file.download
    end

    def processor
      PmacsRefile.processors.fetch(params[:processor]) do |name|
        log_error("Could not find processor: #{name}")
        halt 404
      end
    end

    def log_error(message)
      logger.error "#{self.class.name}: #{message}"
    end

    def verified?
      base_path = request.fullpath.gsub(::File.join(request.script_name, params[:token]), "")

      PmacsRefile.valid_token?(base_path, params[:token]) && not_expired?(params)
    end

    def not_expired?(params)
      params["expires_at"].nil? ||
        (Time.at(params["expires_at"].to_i) > Time.now)
    end

    def force_download?(params)
      !params["force_download"].nil?
    end
  end
end
