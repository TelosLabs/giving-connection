class InstagramPost < ActiveRecord::Base
  validates :external_id, presence: true
  validates :post_url, presence: true
  validates :media_url, presence: true
  validates :creation_date, presence: true
end
