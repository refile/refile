module AttachmentHelper
  def attachment_url(record, name, *args, filename: nil, format: nil)
    file = record.send(name)

    filename ||= name.to_s

    backend_name = Defile.backends.key(file.backend)
    host = Defile.host || root_url

    File.join(host, defile_app_path, backend_name, *args.map(&:to_s), file.id, filename.parameterize("_"))
  end

  def attachment_image_tag(record, name, *args, fallback: nil, format: nil, **options)
    file = record.send(name)

    if file
      image_tag(attachment_url(record, name, *args, format: format), options)
    elsif fallback
      image_tag(fallback, options)
    end
  end

  def attachment_field(object_name, method, options = {})
    if options[:object]
      cache = options[:object].send(:"#{method}_attachment").cache

      if options[:direct]
        host = Defile.host || root_url
        backend_name = Defile.backends.key(cache)

        options[:data] ||= {}
        options[:data][:direct] = true
        options[:data][:as] = "file"
        options[:data][:url] = File.join(host, defile_app_path, backend_name)
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
