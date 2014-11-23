module Defile
  module ActiveRecord
    module Attachment
      include Defile::Attachment

      def attachment(name, cache: :cache, store: :store, raise_errors: false)
        super

        attachment = "#{name}_attachment"

        validate do
          errors = send(attachment).errors
          self.errors.add(name, *errors) unless errors.empty?
        end

        before_save do
          send(attachment).store!
        end
      end
    end
  end
end

::ActiveRecord::Base.extend(Defile::ActiveRecord::Attachment)
