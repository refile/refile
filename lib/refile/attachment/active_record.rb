module Refile
  module ActiveRecord
    module Attachment
      include Refile::Attachment

      # Attachment method which hooks into ActiveRecord models
      #
      # @see Refile::Attachment#attachment
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

        after_destroy do
          send(attachment).delete!
        end
      end
    end
  end
end

::ActiveRecord::Base.extend(Refile::ActiveRecord::Attachment)
