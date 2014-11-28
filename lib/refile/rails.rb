require "refile"

module Refile
  module Controller
    def show
      file = Refile.backends.fetch(params[:backend_name]).get(params[:id])

      options = { disposition: "inline" }
      options[:type] = Mime::Type.lookup_by_extension(params[:format]).to_s if params[:format]

      send_data file.read, options
    end
  end

  module AttachmentFieldHelper
    def attachment_field(method, options = {})
      self.multipart = true
      @template.attachment_field(@object_name, method, objectify_options(options))
    end
  end

  class Engine < Rails::Engine
    initializer "refile", before: :load_environment_config do
      Refile.store ||= Refile::Backend::FileSystem.new(Rails.root.join("tmp/uploads/store").to_s)
      Refile.cache ||= Refile::Backend::FileSystem.new(Rails.root.join("tmp/uploads/cache").to_s)

      Refile.app = Refile::App.new(logger: Rails.logger)

      ActiveSupport.on_load :active_record do
        require "refile/attachment/active_record"
      end

      ActionView::Helpers::FormBuilder.send(:include, AttachmentFieldHelper)
    end
  end
end
