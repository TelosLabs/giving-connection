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
  include PgSearch::Model
  multisearchable against: [:name]

  enum non_standard_office_hours: {appointment_only: 1, always_open: 2, no_set_business_hours: 3}

  belongs_to :organization, optional: true

  scope :active, -> { joins(:organization).where(organization: {active: true}) }
  scope :public_address, -> { where(public_address: true) }
  scope :besides_po_boxes, -> { where(po_box: false) }
  # scope :in_nashville, -> { where("ST_DWithin(lonlat, ST_GeographyFromText('SRID=4326;POINT(-86.78125827725053 36.16404968727089)'), 1000000) = true") }
  scope :locations_with_, ->(cause) { group(:id).joins(:causes).where(causes: {id: cause.id}) }

  has_many :office_hours
  has_many :favorite_locations, dependent: :destroy
  has_many :tags, through: :organization
  has_many :location_services, dependent: :destroy
  has_many :services, through: :location_services
  has_many :causes, through: :organization
  has_many_attached :images

  has_one :phone_number, dependent: :destroy
  has_one :social_media, through: :organization

  validates_with LocationValidator
  validates :name, presence: true
  validates :address, presence: true
  validates :latitude, presence: true
  validates :longitude, presence: true
  validates :lonlat, presence: true
  validates :main, inclusion: {in: [true, false]}
  validates :offer_services, inclusion: {in: [true, false]}
  validates :non_standard_office_hours, inclusion: {in: non_standard_office_hours.keys}, allow_blank: true

  scope :additional, -> { where(main: false) }
  scope :main, -> { where(main: true) }

  before_validation :lonlat_geo_point

  delegate :social_media, to: :organization

  accepts_nested_attributes_for(
    :office_hours,
    reject_if: :blank_office_hours,
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
    address.split(',').insert(1, suite).join(', ')
  end

  def link_to_google_maps
    "https://www.google.com/maps/search/#{address}"
  end

  def self.sort_by_more_services(locations)
    locations
      .joins(:services)
      .group(:id)
      .order('count(services.id) DESC')
  end

  private

  def lonlat_geo_point
    self.lonlat = Geo.point(longitude, latitude)
  end

  def blank_office_hours(attributes)
    attributes['open_time'].blank? &&
      attributes['close_time'].blank? &&
      attributes['closed'].blank?
  end
end
