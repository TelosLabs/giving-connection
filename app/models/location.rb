class Location < ActiveRecord::Base

  before_validation :lonlat_geo_point

  private

  # Example of how to create a geometric point in a spherical reference
  #  Coordinates Tee Zone Driving Range
  #  Geo.point(-100.19098916137905, 25.49941002478492)
  def lonlat_geo_point
    self.lonlat = Geo.point(longitude, latitude)
  end
end
