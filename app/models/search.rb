# frozen_string_literal: true

class Search
  include ActiveModel::Model

  DEFAULT_LOCATION = {
    latitude: 36.16404968727089,
    longitude: -86.78125827725053
  }.freeze

  attr_accessor :keyword, :kilometers, :results, :distance, :city, :state,
                :beneficiary_groups, :services, :open_now, :open_weekends

  validates :keyword, presence: true

  def keyword_search
    # @results = Location.geo_near(Geo.to_wkt(Geo.point(DEFAULT_LOCATION[:longitude], DEFAULT_LOCATION[:latitude])), kilometers.to_i).search_by_keyword(keyword) if valid?
    @results = Location.search_by_keyword(keyword) if valid?
  end

  def filter_search
    filters = { distance: distance, city: city, state: state,
                open_now: open_now, open_weekends: open_weekends,
                beneficiary_groups: beneficiary_groups, services: services }
    @results = FilterQuery.new(filters).search_by_filter
  end
end
