# frozen_string_literal: true

class Search
  include ActiveModel::Model

  KEYWORD_SEARCH_TYPE = "keyword"
  FILTER_SEARCH_TYPE = "filter"

  # "Give" pill values. These strings are both the submitted param value and
  # the label shown on the pill, so they must stay in sync with the SQL in
  # Locations::FilterQuery::GIVE_CONDITIONS.
  GIVE_DONATION = "Donation Opportunities"
  GIVE_VOLUNTEER = "Volunteer Opportunities"
  GIVE_IN_KIND = "In Kind Donations Accepted"
  GIVE_OPTIONS = [GIVE_DONATION, GIVE_VOLUNTEER, GIVE_IN_KIND].freeze

  attr_accessor :keyword, :results, :distance, :city, :state, :zipcode,
    :beneficiary_groups, :services, :causes, :open_now, :open_weekends,
    :scope_of_work, :lat, :lon, :give

  def save
    raise ActiveRecord::RecordInvalid unless valid?

    execute_search
    true
  rescue ActiveRecord::RecordInvalid => e
    false
  end

  def execute_search
    @results = (city == "Search all") ? Location.active : geolocation_query

    # Filter and keyword search
    filtered_ids = Locations::FilterQuery.call(filters, @results).ids
    @results = Location.joins(:organization).where(id: filtered_ids)
    # by_give ranks locations by how many "Give" pills they match. Replay that
    # order here, but only for give searches with no keyword: in_order_of emits
    # one CASE branch per id, and it would otherwise outrank pg_search's
    # relevance ordering on every keyword search.
    @results = @results.in_order_of(:id, filtered_ids) if rank_by_give?
    @results = keyword.present? ? Locations::KeywordQuery.call({keyword: keyword}, @results) : @results
  end

  def to_params
    {
      keyword: keyword,
      city: city,
      state: state,
      lat: lat,
      lon: lon,
      distance: distance,
      causes: causes,
      services: services,
      beneficiary_groups: beneficiary_groups,
      open_now: open_now,
      open_weekends: open_weekends,
      scope_of_work: scope_of_work,
      zipcode: zipcode,
      give: give
    }.compact
  end

  private

  def rank_by_give?
    give.present? && keyword.blank?
  end

  def geolocation_query
    @results = Locations::GeolocationQuery.call(geo_filters)
    # Merge with national or international locations
    national_or_international_locations = Location.national_and_international.ids
    Location.where(id: @results.ids + national_or_international_locations).distinct
  end

  def filters
    {
      address: {city: city.presence, state: state.presence, zipcode: zipcode.presence},
      open_now: ActiveModel::Type::Boolean.new.cast(open_now),
      open_weekends: ActiveModel::Type::Boolean.new.cast(open_weekends),
      beneficiary_groups: beneficiary_groups&.transform_values { |value| value.uniq },
      services: services&.transform_values { |value| value.uniq },
      causes: causes&.uniq,
      scope_of_work: scope_of_work,
      give: give&.uniq
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
