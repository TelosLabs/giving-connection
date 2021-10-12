class Location < ActiveRecord::Base
  include Locations::Searchable

  before_validation :lonlat_geo_point

  private

  def lonlat_geo_point
    self.lonlat = Geo.point(longitude, latitude)
  end
end
