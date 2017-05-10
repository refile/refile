require "pmacs_refile"
require "pmacs_refile/rails/attachment_helper"

module PmacsRefile
  # @api private
  class Engine < Rails::Engine
    initializer "pmacs_refile.setup", before: :load_environment_config do
      if RUBY_PLATFORM == "java"
        # Work around a bug in JRuby, see: https://github.com/jruby/jruby/issues/2779
        Encoding.default_internal = nil
      end

      PmacsRefile.store ||= PmacsRefile::Backend::FileSystem.new(Rails.root.join("tmp/uploads/store").to_s)
      PmacsRefile.cache ||= PmacsRefile::Backend::FileSystem.new(Rails.root.join("tmp/uploads/cache").to_s)

      ActiveSupport.on_load :active_record do
        require "pmacs_refile/attachment/active_record"
      end

      ActionView::Base.send(:include, PmacsRefile::AttachmentHelper)
      ActionView::Helpers::FormBuilder.send(:include, AttachmentHelper::FormBuilder)
    end

    initializer "pmacs_refile.app" do
      PmacsRefile.logger = Rails.logger
      PmacsRefile.app = PmacsRefile::App.new
    end

    initializer "pmacs_refile.secret_key" do |app|
      PmacsRefile.secret_key ||= if app.respond_to?(:secrets)
        app.secrets.secret_key_base
      elsif app.config.respond_to?(:secret_key_base)
        app.config.secret_key_base
      elsif app.config.respond_to?(:secret_token)
        app.config.secret_token
      end
    end
  end
end

# Add in missing methods for file uploads in Rails < 4
ActionDispatch::Http::UploadedFile.class_eval do
  unless instance_methods.include?(:eof?)
    def eof?
      @tempfile.eof?
    end
  end

  unless instance_methods.include?(:close)
    def close
      @tempfile.close
    end
  end
end
