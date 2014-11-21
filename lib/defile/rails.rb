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

  class Engine < Rails::Engine
    initializer "defile.setup_backend" do
      Defile.store = Defile::Backend::FileSystem.new(Rails.root.join("tmp/uploads/store").to_s)
      Defile.cache = Defile::Backend::FileSystem.new(Rails.root.join("tmp/uploads/cache").to_s)
    end

    initializer "defile.setup_app" do
      Defile.app = Defile::App.new(logger: Rails.logger)
    end

    initializer "defile.active_record" do
      ActiveSupport.on_load :active_record do
        require "defile/attachment/active_record"
      end
    end
  end
end
