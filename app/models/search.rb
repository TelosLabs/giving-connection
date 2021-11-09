# frozen_string_literal: true

class Search
  include ActiveModel::Model

  attr_accessor :keyword, :kilometers, :results

  validates :keyword, presence: true

  def save
    if valid?
      @results = Organization.geolocation_search(kilometers: kilometers).search_by_keyword(keyword)
    end
  end
end
