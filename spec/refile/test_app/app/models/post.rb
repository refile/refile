class Post < ActiveRecord::Base
  attr_accessor :requires_document

  attachment :image, type: :image
  attachment :document, cache: :limited_cache
  validates_presence_of :title

  has_many :documents, dependent: :destroy
  accepts_attachments_for :documents

  validates_presence_of :document, if: :requires_document?

private

  def requires_document?
    !requires_document.to_i.zero?
  end
end
