class Document < ActiveRecord::Base
  belongs_to :post
  attachment :file, cache: :limited_cache
end
