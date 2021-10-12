class Search
  include ActiveModel::Model

  # TODO Change to center of Nashville
  DEFAULT_LOCATION = {
    latitude: 25.499213,
    longitude: -100.190962
  }

  attr_accessor :keyword, :kilometers, :results

  validates :keyword, presence: true

  def save
    if valid?
      # from tee zone
      @results = Location.geo_near(Geo.to_wkt(Geo.point(DEFAULT_LOCATION[:longitude], DEFAULT_LOCATION[:latitude])),kilometers.to_i).search_by_keyword(keyword)
    end
  end
end
