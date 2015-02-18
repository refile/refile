module Refile
  module ActiveRecord
    module Attachment
      include Refile::Attachment

      # Attachment method which hooks into ActiveRecord models
      #
      # @see Refile::Attachment#attachment
      def attachment(name, raise_errors: false, **options)
        super

        attacher = "#{name}_attacher"

        validate do
          if send(attacher).present?
            send(attacher).valid?
            errors = send(attacher).errors
            errors.each do |error|
              self.errors.add(name, error)
            end
          end
        end

        before_save do
          send(attacher).store!
        end

        after_destroy do
          send(attacher).delete!
        end
      end
    end
  end
end

::ActiveRecord::Base.extend(Refile::ActiveRecord::Attachment)
