# frozen_string_literal: true

class Search
  include ActiveModel::Model

  KEYWORD_SEARCH_TYPE = 'keyword'
  FILTER_SEARCH_TYPE = 'filter'

  attr_accessor :keyword, :results, :distance, :city, :state, :zip_code,
                :beneficiary_groups, :services, :open_now, :open_weekends,
                :search_type

  validates :keyword, presence: true, if: proc { search_type == KEYWORD_SEARCH_TYPE }
  validates :search_type, presence: true

  def save
    raise ActiveRecord::RecordInvalid unless valid?

    execute_keyword_search if keyword_search?
    execute_filter_search if filter_search?
    true
  rescue ActiveRecord::RecordInvalid => e
    false
  end

  def keyword_search?
    search_type == KEYWORD_SEARCH_TYPE
  end

  def filter_search?
    search_type == FILTER_SEARCH_TYPE
  end

  def execute_keyword_search
    @results = Locations::KeywordQuery.call({ keyword: keyword })
  end

  def execute_filter_search
    filters = {
      address: { city: city, state: state, zip_code: zip_code },
      open_now: ActiveModel::Type::Boolean.new.cast(open_now),
      open_weekends: ActiveModel::Type::Boolean.new.cast(open_weekends),
      beneficiary_groups: beneficiary_groups, services: services,
      distance: distance.to_i
    }

    @results = Locations::FilterQuery.call(filters)
  end
end
