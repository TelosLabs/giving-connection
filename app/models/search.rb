# frozen_string_literal: true

class Search
  include ActiveModel::Model

  KEYWORD_SEARCH_TYPE = "keyword"
  FILTER_SEARCH_TYPE = "filter"

  attr_accessor :keyword, :results, :distance, :city, :state, :zipcode,
    :beneficiary_groups, :services, :causes, :open_now, :open_weekends,
    :lat, :lon

  def save
    raise ActiveRecord::RecordInvalid unless valid?

    execute_search
    true
  rescue ActiveRecord::RecordInvalid => e
    false
  end

  def execute_search
    @results = Location.active
    @results = geolocation_query if city != "Search all"

    # Filter and keyword search
    @results = Location.joins(:organization).where(id: Locations::FilterQuery.call(filters, @results).ids)
    @results = keyword.present? ? Locations::KeywordQuery.call({keyword: keyword}, @results) : @results
  end

  private

  def geolocation_query
    # Geolocation search
    Locations::GeolocationQuery.call(geo_filters)
    # Merge with national or international locations
    national_or_international_locations = Location.national_and_international.ids
    Location.where(id: @results.ids + national_or_international_locations).distinct
  end

  def filters
    {
      address: {city: city.presence, state: state.presence, zipcode: zipcode.presence},
      open_now: ActiveModel::Type::Boolean.new.cast(open_now),
      open_weekends: ActiveModel::Type::Boolean.new.cast(open_weekends),
      beneficiary_groups: beneficiary_groups,
      services: services,
      causes: causes
    }
  end

  def geo_filters
    {
      distance: distance.presence&.to_i,
      lat: lat.presence&.to_f,
      lon: lon.presence&.to_f
    }
  end
end
