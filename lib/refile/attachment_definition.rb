module Refile
  # @api private
  class AttachmentDefinition
    attr_reader :record, :name, :cache, :store, :options, :type, :valid_extensions, :valid_content_types
    attr_accessor :remove

    def initialize(name, cache:, store:, raise_errors: true, type: nil, extension: nil, content_type: nil)
      @name = name
      @raise_errors = raise_errors
      @cache_name = cache
      @store_name = store
      @type = type
      @valid_extensions = [extension].flatten if extension
      @valid_content_types = [content_type].flatten if content_type
      @valid_content_types ||= Refile.types.fetch(type).content_type if type
    end

    def cache
      Refile.backends.fetch(@cache_name.to_s)
    end

    def store
      Refile.backends.fetch(@store_name.to_s)
    end

    def accept
      if valid_content_types
        valid_content_types.join(",")
      elsif valid_extensions
        valid_extensions.map { |e| ".#{e}" }.join(",")
      end
    end

    def raise_errors?
      @raise_errors
    end

    def validate(attacher)
      errors = []
      extension_included = valid_extensions && valid_extensions.map(&:downcase).include?(attacher.extension.to_s.downcase)
      errors << :invalid_extension if valid_extensions and not extension_included
      errors << :invalid_content_type if valid_content_types and not valid_content_types.include?(attacher.content_type)
      errors << :too_large if cache.max_size and attacher.size and attacher.size >= cache.max_size
      errors
    end
  end
end
