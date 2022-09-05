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
#  name             :string           not null
#  email            :string
#
class Location < ActiveRecord::Base
  include Locations::Searchable
  include Locations::Officeable
  validates_with LocationValidator

  belongs_to :organization, optional: true

  scope :active, -> { joins(:organization).where(organization: { active: true }) }
  scope :besides_po_boxes, -> { where(po_box: false) }

  has_many :office_hours
  has_many :favorite_locations, dependent: :destroy
  has_many :tags, through: :organization
  has_many :location_services, dependent: :destroy
  has_many :services, through: :location_services
  has_many :causes, through: :organization
  has_many_attached :images, service: :s3

  has_one :phone_number, dependent: :destroy
  has_one :social_media, through: :organization

  validates :name, presence: true
  validates :address, presence: true
  validates :latitude, presence: true
  validates :longitude, presence: true
  validates :lonlat, presence: true
  validates :main, inclusion: { in: [true, false] }
  validates :physical, inclusion: { in: [true, false] }
  validates :offer_services, inclusion: { in: [ true, false ] }
  validates :appointment_only, inclusion: { in: [true, false] }

  scope :additional, -> { where(main: false) }
  scope :main, -> { where(main: true) }

  before_validation :lonlat_geo_point

  delegate :social_media, to: :organization

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

  accepts_nested_attributes_for(
    :phone_number,
    reject_if: :all_blank,
    update_only: true
  )

  def formatted_address
    suite.nil? || suite.empty? ? address : address_with_suite_number
  end

  def address_with_suite_number
    address.split(",").insert(1, suite).join(", ")
  end

  def link_to_google_maps
    "https://www.google.com/maps/search/#{address}"
  end

  private

  def lonlat_geo_point
    self.lonlat = Geo.point(longitude, latitude)
  end
end
