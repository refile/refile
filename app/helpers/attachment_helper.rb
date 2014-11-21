module AttachmentHelper
  def attachment_url(record, name, *args, format: nil)
    file = record.send(name)

    backend_name = Defile.backends.key(file.backend)
    host = Defile.host || root_url

    File.join(host, defile_app_path, backend_name, *args.map(&:to_s), file.id)
  end
end
