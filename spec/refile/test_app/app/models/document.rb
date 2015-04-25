class Document < ActiveRecord::Base
  belongs_to :post
  attachment :file
end
