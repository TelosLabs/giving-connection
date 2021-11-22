# frozen_string_literal: true

class Locations::KeywordQuery < ApplicationQuery
  attr_reader :locations

  class << self
    def call(params = {}, locations = Location.all)
      scope = locations
      scope = by_keyword(scope, params[:keyword])
    end

    private

    def by_keyword(scope, keyword)
      scope.search_by_keyword(keyword)
    end
  end
end
