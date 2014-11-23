class Post < ActiveRecord::Base
  attachment :image
  attachment :document, max_size: 100
  validates_presence_of :title
end
