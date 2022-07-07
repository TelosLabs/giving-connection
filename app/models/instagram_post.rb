class InstagramPost < ActiveRecord::Base
  validates :external_id, presence: true
  validates :post_url, presence: true
  validates :media_url, presence: true
  validates :creation_date, presence: true

  scope :latest_six_created, -> { order(creation_date: :desc).order(updated_at: :desc)&.first(6) }
end
