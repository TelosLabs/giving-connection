class Search
  include ActiveModel::Model

  DEFAULT_LOCATION = {
    latitude: 36.16404968727089,
    longitude: -86.78125827725053
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
