module Defile
  module ActiveRecord
    module Attachment
      include Defile::Attachment

      def attachment(name, type:, max_size: Float::INFINITY, cache_name: :cache, store_name: :store)
        super

        before_save :"store_#{name}"

      end
    end
  end
end

::ActiveRecord::Base.extend(Defile::ActiveRecord::Attachment)
