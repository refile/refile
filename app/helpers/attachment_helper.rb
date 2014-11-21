module AttachmentHelper
  def attachment_url(record, name, *args, format: nil)
    file = record.send(name)

    backend_name = Defile.backends.key(file.backend)
    host = Defile.host || root_url

    File.join(host, defile_app_path, backend_name, *args.map(&:to_s), file.id)
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
    hidden_field(object_name, :"#{method}_cache_id", options) +
    file_field(object_name, method, options)
  end
end
