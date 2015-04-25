class Post < ActiveRecord::Base
  attachment :image, type: :image
  attachment :document, cache: :limited_cache
  validates_presence_of :title

  has_many :documents
  accepts_attachments_for :documents
end
