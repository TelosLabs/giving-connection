# frozen_string_literal: true

# == Schema Information
#
# Table name: locations
#
#  id               :bigint           not null, primary key
#  address          :string
#  latitude         :decimal(10, 6)
#  longitude        :decimal(10, 6)
#  lonlat           :geography        not null, point, 4326
#  website          :string
#  main             :boolean          default(FALSE), not null
#  physical         :boolean
#  offer_services   :boolean
#  organization_id  :bigint
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  appointment_only :boolean          default(FALSE)
#
class Location < ActiveRecord::Base
  include Locations::Searchable
  validates_with LocationsValidator

  belongs_to :organization, optional: true
  has_many :office_hours
  has_many :favorite_locations
  has_many :location_services, dependent: :destroy
  has_many :services, through: :location_services
  belongs_to :organization, optional: true

  has_many :tags, through: :organization
  has_one :social_media, through: :organization

  validates :address, presence: true
  validates :latitude, presence: true
  validates :longitude, presence: true
  validates :lonlat, presence: true
  validates :main, inclusion: { in: [ true, false ] }
  validates :physical, inclusion: { in: [ true, false ] }
  validates :offer_services, inclusion: { in: [ true, false ] }
  validates :appointment_only, inclusion: { in: [ true, false ] }
  # validates :office_hours, length: { minimum: 7, maximum: 7 }

  # delegate :tags, :to => :organization, :prefix => true
  # delegate :social_media, :to => :organization, :prefix => true

  scope :additional, -> { where(main: false) }
  scope :main, -> { where(main: true) }

  before_validation :lonlat_geo_point

  accepts_nested_attributes_for(
    :office_hours,
    reject_if: :all_blank,
    allow_destroy: true
  )

  accepts_nested_attributes_for(
    :location_services,
    reject_if: :all_blank,
    allow_destroy: true
  )

  private

  def lonlat_geo_point
    self.lonlat = Geo.point(longitude, latitude)
  end
end
