# Newer versions of Rails have already added this, polyfilling it in.

unless ActionDispatch::Http::UploadedFile.instance_methods.include?(:to_io)
  ActionDispatch::Http::UploadedFile.send(:alias_method, :to_io, :tempfile)
end
