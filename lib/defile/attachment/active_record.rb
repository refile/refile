module Defile
  module ActiveRecord
    module Attachment
      include Defile::Attachment

      def attachment(name, type:, max_size: Float::INFINITY, cache: :cache, store: :store, raise_errors: false)
        super

        before_save do
          send("#{name}_attachment").store!
        end
      end
    end
  end
end

::ActiveRecord::Base.extend(Defile::ActiveRecord::Attachment)
