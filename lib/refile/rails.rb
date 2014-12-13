require "refile"
require "refile/rails/attachment_helper"

module Refile
  module AttachmentFieldHelper
    def attachment_field(method, options = {})
      self.multipart = true
      @template.attachment_field(@object_name, method, objectify_options(options))
    end
  end

  class Engine < Rails::Engine
    initializer "refile.setup", before: :load_environment_config do
      Refile.store ||= Refile::Backend::FileSystem.new(Rails.root.join("tmp/uploads/store").to_s)
      Refile.cache ||= Refile::Backend::FileSystem.new(Rails.root.join("tmp/uploads/cache").to_s)

      ActiveSupport.on_load :active_record do
        require "refile/attachment/active_record"
      end

      ActionView::Base.send(:include, Refile::AttachmentHelper)
      ActionView::Helpers::FormBuilder.send(:include, AttachmentFieldHelper)
    end

    initializer "refile.app" do
      Refile.app = Refile::App.new(logger: Rails.logger)
    end
  end
end
