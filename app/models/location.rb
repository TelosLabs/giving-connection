# == Schema Information
#
# Table name: locations
#
#  id             :bigint           not null, primary key
#  address        :string
#  latitude       :decimal(10, 6)
#  longitude      :decimal(10, 6)
#  lonlat         :geography        not null, point, 4326
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  website        :string
#  main           :boolean          default(FALSE), not null
#  physical       :boolean
#  offer_services :boolean
#
class Location < ActiveRecord::Base
  include Locations::Searchable

  belongs_to :organization

  before_validation :lonlat_geo_point

  private

  def lonlat_geo_point
    self.lonlat = Geo.point(longitude, latitude)
  end
end
