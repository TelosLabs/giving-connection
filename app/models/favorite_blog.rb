# frozen_string_literal: true

# == Schema Information
#
# Table name: favorite_blogs
#
#  id          :bigint           not null, primary key
#  user_id     :bigint           not null
#  blog_id :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class FavoriteBlog < ApplicationRecord
  belongs_to :user
  belongs_to :blog

  validates :blog_id, uniqueness: {scope: :user_id}
end
