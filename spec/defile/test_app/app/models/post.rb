class Post < ActiveRecord::Base
  attachment :image, type: :image
  validates_presence_of :title
end
