require "defile"

module Defile
  module Controller
    def show
      file = Defile.backends.fetch(params[:backend_name]).get(params[:id])

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
    initializer "defile", before: :load_environment_config do
      Defile.store = Defile::Backend::FileSystem.new(Rails.root.join("tmp/uploads/store").to_s)
      Defile.cache = Defile::Backend::FileSystem.new(Rails.root.join("tmp/uploads/cache").to_s)

      Defile.app = Defile::App.new(logger: Rails.logger)

      ActiveSupport.on_load :active_record do
        require "defile/attachment/active_record"
      end

      ActionView::Helpers::FormBuilder.send(:include, AttachmentFieldHelper)
    end
  end
end
