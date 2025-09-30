class Blog < ApplicationRecord
  has_rich_text :content
  has_many_attached :images
  has_one_attached :cover_image

  validates :title, presence: true
end
