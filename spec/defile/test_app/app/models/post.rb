class Post < ActiveRecord::Base
  attachment :image, type: :image
  attachment :document, type: :any
  validates_presence_of :title
end
