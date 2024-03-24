# frozen_string_literal: true

class Search
  include ActiveModel::Model

  KEYWORD_SEARCH_TYPE = "keyword"
  FILTER_SEARCH_TYPE = "filter"
  DEFAULT_CITY = "Nashville"
  AVAILABLE_CITIES = ["Nashville", "Atlantic City"].freeze

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
    @results = Location.where(id: Locations::FilterQuery.call(filters, Location.active).pluck(:id))
    @results = keyword.present? ? Locations::KeywordQuery.call({keyword: keyword}, @results) : @results
  end

  private

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
