class Blog < ApplicationRecord
  has_rich_text :content
  has_many_attached :images
  has_one_attached :cover_image

  has_many :blog_likes, dependent: :destroy
  has_many :likers, through: :blog_likes, source: :user

  validates :title, presence: true
end
