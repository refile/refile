require "logger"
require "json"

module Refile
  class App

    attr_accessor :logger, :allow_origin

    def initialize(logger: nil, allow_origin: nil)
      @logger = logger || ::Logger.new(nil)
      @allow_origin = allow_origin
    end

    # @api private
    class Proxy

      attr_accessor :peek, :file

      def initialize(peek, file)
        @peek = peek
        @file = file
      end

      def close
        file.close
      end

      def each(&block)
        block.call(peek)
        file.each(&block)
      end
    end

    def call(env)
      begin
        logger.info { "Refile: #{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}" }

        request_type_downcased = env["REQUEST_METHOD"].downcase

        if request_should_be_handled?(request_type_downcased, env)
          send("handle_#{request_type_downcased}_request", env)
        else
          not_found
        end
      rescue => e
        log_error(e)
        internal_server_error
      ensure
        reset_env_data
      end
    end

  private

    def not_found
      [404, {}, ["not found"]]
    end

    def internal_server_error
      [500, {}, ["error"]]
    end

    def log_error(e)
      if logger.debug?
        logger.debug "Refile: unable to read file"
        logger.debug "#{e.class}: #{e.message}"
        e.backtrace.each do |line|
          logger.debug "  #{line}"
        end
      end
    end

    def fetch_env_data_from env
      if @env_data.nil?
        backend_name, *args = env["PATH_INFO"].sub(/^\//, "").split("/")
        backend = Refile.backends[backend_name]
        @env_data = [ backend_name, args, backend ]
      end

      @env_data
    end

    def reset_env_data
      @env_data = nil
    end

    def request_should_be_handled? request_type, env
      backend_name, args, backend = fetch_env_data_from(env)
      case request_type
      when "get"
        backend and args.length >= 2
      when "post"
        backend and args.empty? and Refile.direct_upload.include?(backend_name)
      else
        false
      end
    end

    def handle_get_request env
      backend_name, args, backend = fetch_env_data_from(env)

      *process_args, id, filename = args
      format = ::File.extname(filename)[1..-1]

      logger.debug { "Refile: serving #{id.inspect} from #{backend_name} backend which is of type #{backend.class}" }

      file = backend.get(id)

      unless process_args.empty?
        name = process_args.shift
        processor = Refile.processors[name]
        unless processor
          logger.debug { "Refile: no such processor #{name.inspect}" }
          return not_found
        end
        file = if format
          processor.call(file, *process_args, format: format)
        else
          processor.call(file, *process_args)
        end
      end

      peek = begin
        file.read(Refile.read_chunk_size)
      rescue => e
        log_error(e)
        return not_found
      end

      headers = {}
      headers["Access-Control-Allow-Origin"] = @allow_origin if @allow_origin

      [200, headers, Proxy.new(peek, file)]
    end

    def handle_post_request env
      backend_name, args, backend = fetch_env_data_from(env)

      logger.debug { "Refile: uploading to #{backend_name} backend which is of type #{backend.class}" }

      tempfile = Rack::Request.new(env).params.fetch("file").fetch(:tempfile)
      file = backend.upload(tempfile)

      [200, { "Content-Type" => "application/json" }, [{ id: file.id }.to_json]]
    end

    def method_missing(name, *args)
      return not_found if name =~ /^handle_(\.)*_request/
      super(name, args)
    end
  end
end
