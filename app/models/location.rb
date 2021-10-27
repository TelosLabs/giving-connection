# frozen_string_literal: true

# == Schema Information
#
# Table name: locations
#
#  id              :bigint           not null, primary key
#  address         :string
#  latitude        :decimal(10, 6)
#  longitude       :decimal(10, 6)
#  lonlat          :geography        not null, point, 4326
#  website         :string
#  string          :string
#  main            :boolean          default(FALSE), not null
#  physical        :boolean
#  offer_services  :boolean
#  organization_id :bigint
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class Location < ActiveRecord::Base
  include Locations::Searchable

  has_many :office_hours
  belongs_to :organization

  # TODO add validations
  validates :address, presence: true
  validates :latitude, presence: true
  validates :longitude, presence: true
  validates :lonlat, presence: true
  validates :main, presence: true
  validates :physical, presence: true
  validates :offer_services, presence: true
  # validate :single_main_location
  # validates :office_hours, length: { minimum: 7, maximum: 7 }

  scope :additional, -> { where(main: false) }
  scope :main, -> { where(main: true) }

  before_validation :lonlat_geo_point

  private

  # def single_main_location
  #   organization.locations.
  # end

  def lonlat_geo_point
    self.lonlat = Geo.point(longitude, latitude)
  end
end
