require "logger"

module Defile
  class App
    NOT_FOUND = [404, {}.freeze, ["not found"].freeze]

    def initialize(logger: nil, allow_origin: nil)
      @logger = logger
      @logger ||= ::Logger.new(nil)
      @allow_origin = allow_origin
    end

    def call(env)
      if env["REQUEST_METHOD"] == "GET"
        backend_name, id = env["PATH_INFO"].sub(/^\//, "").split("/")
        backend = Defile.backends[backend_name]

        if backend and id
          file = backend.get(id)
          begin
            # Performance tweak: instead of checking for file existence, we just
            # try to read from the file, and cache the result.
            file.peek
          rescue => e
            if @logger.debug?
              @logger.debug "Defile: unable to read file #{id}"
              @logger.debug "#{e.class}: #{e.message}"
              e.backtrace.each do |line|
                @logger.debug "  #{line}"
              end
            end
            return NOT_FOUND
          end
          @logger.debug { "Defile: serving #{id.inspect} from #{backend_name} backend which is of type #{backend.class}" }

          headers = {}
          headers["Access-Control-Allow-Origin"] = @allow_origin if @allow_origin

          [200, headers, file]
        else
          @logger.debug { "Defile: must specify backend and id" }
          NOT_FOUND
        end
      else
        @logger.debug { "Defile: request methods other than GET are not allowed" }
        NOT_FOUND
      end
    end
  end
end
