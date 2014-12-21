class Post < ActiveRecord::Base
  attachment :image, type: :image
  attachment :document, cache: :limited_cache
  validates_presence_of :title
end
