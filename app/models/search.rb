# frozen_string_literal: true

class Search
  include ActiveModel::Model

  KEYWORD_SEARCH_TYPE = 'keyword'
  FILTER_SEARCH_TYPE = 'filter'

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
    filters = {
      open_now: ActiveModel::Type::Boolean.new.cast(open_now),
      open_weekends: ActiveModel::Type::Boolean.new.cast(open_weekends),
      beneficiary_groups: beneficiary_groups,
      services: services,
      causes: causes,
      distance: distance.presence&.to_i,
      address: { city: city.presence, state: state.presence, zipcode: zipcode.presence }
    }

    @results = keyword.present? ? Locations::KeywordQuery.call({ keyword: keyword }) : Location.active
    @results = Locations::FilterQuery.call(filters, @results)
  end
end
