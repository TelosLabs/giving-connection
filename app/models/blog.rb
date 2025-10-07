class Blog < ApplicationRecord
  belongs_to :user, optional: true
  has_rich_text :content
  has_many_attached :images
  has_one_attached :cover_image

  has_many :blog_likes, dependent: :destroy
  has_many :likers, through: :blog_likes, source: :user
  
  attr_accessor :share_consent
  
  validates :title, presence: true
  validates :share_consent, acceptance: { accept: "1", message: "must be accepted to publish your story" }

  scope :published, -> { where(published: true) }

end
