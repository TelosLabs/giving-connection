class RandomCoordinatesGenerator < ApplicationService
  EARTH_RADIOUS = 6371 # km
  ONE_DEGREE = EARTH_RADIOUS * 2 * Math::PI / 360 * 1000 # 1° latitude in meters

  def initialize(central_lat:, central_lng:, max_radius:)
    @central_lat = central_lat
    @central_lng = central_lng
    @max_radius = max_radius
  end

  def call
    random_coords = {}

    dx, dy = random_point_in_disk
    random_coords[:lat] = @central_lat + (dy / ONE_DEGREE)
    random_coords[:lng] = @central_lng + (dx / (ONE_DEGREE * Math.cos(@central_lat * Math::PI / 180)))
    random_coords
  end

  def random_point_in_disk
    r = @max_radius * (rand**0.5)
    theta = rand * 2 * Math::PI
    [r * Math.cos(theta), r * Math.sin(theta)]
  end
end
