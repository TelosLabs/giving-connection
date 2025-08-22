class Event < ApplicationRecord
  belongs_to :organization
  has_one_attached :image

  validates :title, :start_time, presence: true
end
