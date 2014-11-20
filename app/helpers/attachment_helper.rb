module AttachmentHelper
  def attachment_url(record, name, options = {})
    file = record.send(name)

    backend_name = Defile.backends.key(file.store)

    options = options.merge(
      backend_name: backend_name,
      id: file.id
    )
    attachment_route_url(options)
  end
end
