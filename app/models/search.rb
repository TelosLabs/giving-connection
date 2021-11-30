# frozen_string_literal: true

class Search
  include ActiveModel::Model

  KEYWORD_SEARCH_TYPE = 'keyword'
  FILTER_SEARCH_TYPE = 'filter'

  attr_accessor :keyword, :results, :distance, :city, :state, :zipcode,
                :beneficiary_groups, :services, :open_now, :open_weekends

  def save
    begin
      raise ActiveRecord::RecordInvalid unless valid?
      execute_search
      true
    rescue ActiveRecord::RecordInvalid => invalid
      false
    end
  end

  def execute_search
    filters = {
      address: { city: city.presence, state: state.presence, zipcode: zipcode.presence },
                open_now: ActiveModel::Type::Boolean.new.cast(open_now),
                open_weekends: ActiveModel::Type::Boolean.new.cast(open_weekends),
                beneficiary_groups: beneficiary_groups, services: services,
                distance: distance.presence&.to_i
               }
    @results = keyword.present? ? Locations::KeywordQuery.call({keyword: keyword}) : Location.all
    @results = Locations::FilterQuery.call(filters, @results)
  end
end
