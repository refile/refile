require "defile"

module Defile
  class Railtie < Rails::Railtie
    initializer "defile.setup_backend" do
      Defile.store = Defile::Backend::FileSystem.new(Rails.root.join("tmp/uploads/store").to_s)
      Defile.cache = Defile::Backend::FileSystem.new(Rails.root.join("tmp/uploads/cache").to_s)
    end

    initializer "defile.active_record" do
      ActiveSupport.on_load :active_record do
        require "defile/attachment/active_record"
      end
    end
  end
end
