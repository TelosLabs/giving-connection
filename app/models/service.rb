# frozen_string_literal: true

# == Schema Information
#
# Table name: services
#
#  id         :bigint           not null, primary key
#  name       :string
#  cause_id   :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Service < ApplicationRecord
  include PgSearch::Model
  multisearchable against: :name

  belongs_to :cause
  has_many :location_services, dependent: :destroy
  has_many :locations, through: :location_services

  validates :name, presence: true, uniqueness: true

  # Adding/renaming a service changes the cached causes-to-services hash even though the Cause record itself didn't change.
  after_commit -> { Rails.cache.delete_multi(%w[search_pills/services select_multiple/causes_with_services]) }

  def self.top(limit: 10)
    find(top_services_ids(limit: limit))
  end

  def self.top_services_ids(limit: 10)
    LocationService.group(:service_id).order("count(service_id) desc").limit(limit).count.keys
  end
end
