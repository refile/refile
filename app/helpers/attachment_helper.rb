module AttachmentHelper
  def attachment_url(record, name, options = {})
    file = record.send(name)

    backend_name = Defile.backends.key(file.backend)

    defile_app_url + "/#{backend_name}/#{file.id}"
  end
end
