module Refile
  module AttachmentHelper
    def attachment_url(record, name, *args, filename: nil, format: nil)
      file = record.send(name)
      return unless file

      filename ||= name.to_s

      backend_name = Refile.backends.key(file.backend)
      host = Refile.host || request.base_url

      filename = filename.parameterize("_")
      filename << "." << format.to_s if format

      ::File.join(host, main_app.refile_app_path, backend_name, *args.map(&:to_s), file.id, filename)
    end

    def attachment_image_tag(record, name, *args, fallback: nil, format: nil, **options)
      file = record.send(name)
      classes = ["attachment", record.class.model_name.singular, name, *options[:class]]

      if file
        image_tag(attachment_url(record, name, *args, format: format), options.merge(class: classes))
      elsif fallback
        classes << "fallback"
        image_tag(fallback, options.merge(class: classes))
      end
    end

    def attachment_field(object_name, method, options = {})
      if options[:object]
        cache = options[:object].send(:"#{method}_attachment").cache

        if options[:direct]
          host = Refile.host || request.base_url
          backend_name = Refile.backends.key(cache)

          options[:data] ||= {}
          options[:data][:direct] = true
          options[:data][:as] = "file"
          options[:data][:url] = ::File.join(host, main_app.refile_app_path, backend_name)
        end

        if options[:presigned] and cache.respond_to?(:presign)
          signature = cache.presign
          options[:data] ||= {}
          options[:data][:direct] = true
          options[:data][:id] = signature.id
          options[:data][:url] = signature.url
          options[:data][:fields] = signature.fields
          options[:data][:as] = signature.as
        end
      end
      hidden_field(object_name, :"#{method}_cache_id", options.slice(:object)) +
      file_field(object_name, method, options)
    end
  end
end
