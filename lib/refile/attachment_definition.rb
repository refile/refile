module Refile
  # @api private
  class AttachmentDefinition
    attr_reader :record, :name, :cache, :store, :options, :type, :valid_content_types
    attr_accessor :remove

    def initialize(name, cache:, store:, raise_errors: true, type: nil, extension: nil, content_type: nil)
      @name = name
      @raise_errors = raise_errors
      @cache_name = cache
      @store_name = store
      @type = type
      @extension = extension
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

    def valid_extensions
      return unless @extension
      if @extension.is_a?(Proc)
        Array(@extension.call)
      else
        Array(@extension)
      end
    end

    def validate(attacher)
      extension = attacher.extension.to_s.downcase
      content_type = attacher.content_type.to_s.downcase
      content_type = content_type.split(";").first unless content_type.empty?

      errors = []
      errors << extension_error_params(extension) if invalid_extension?(extension)
      errors << content_type_error_params(content_type) if invalid_content_type?(content_type)
      errors << :too_large if cache.max_size and attacher.size and attacher.size >= cache.max_size
      errors << :zero_byte_detected if attacher.size.to_i.zero?
      errors
    end

  private

    def extension_error_params(extension)
      [:invalid_extension, extension: format_param(extension), permitted: valid_extensions.to_sentence]
    end

    def content_type_error_params(content_type)
      [:invalid_content_type, content: format_param(content_type), permitted: valid_content_types.to_sentence]
    end

    def invalid_extension?(extension)
      extension_included = valid_extensions && valid_extensions.map(&:downcase).include?(extension)
      valid_extensions and not extension_included
    end

    def invalid_content_type?(content_type)
      valid_content_types and not valid_content_types.include?(content_type)
    end

    def format_param(param)
      param.empty? ? I18n.t("refile.empty_param") : param
    end
  end
end
