class BlogLike < ApplicationRecord
  belongs_to :user
  belongs_to :blog
  validates :user_id, uniqueness: { scope: :blog_id }
end