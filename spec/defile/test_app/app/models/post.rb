class Post < ActiveRecord::Base
  attachment :image
  attachment :document
  validates_presence_of :title
end
