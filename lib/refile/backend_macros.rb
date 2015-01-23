module Refile
  # Macros which make it easier to write secure backends.
  #
  # @api private
  module BackendMacros
    def verify_id(method)
      mod = Module.new do
        define_method(method) do |id|
          id = id.to_s
          if self.class.valid_id?(id)
            super(id)
          else
            raise Refile::InvalidID
          end
        end
      end
      prepend mod
    end

    def verify_uploadable(method)
      mod = Module.new do
        define_method(method) do |uploadable|
          [:size, :read, :eof?, :close].each do |m|
            unless uploadable.respond_to?(m)
              raise ArgumentError, "does not respond to `#{m}`."
            end
          end
          if max_size and uploadable.size > max_size
            raise Refile::Invalid, "#{uploadable.inspect} is too large"
          end
          super(uploadable)
        end
      end
      prepend mod
    end

    def valid_id?(id)
      id =~ /\A[a-z0-9]+\z/i
    end
  end
end
