# frozen_string_literal: true

module Locations
  class KeywordQuery < ApplicationQuery
    attr_reader :locations

    class << self
      def call(params = {}, locations = Location.active)
        scope = locations
        scope = by_keyword(scope, params[:keyword])
      end

      private

      def by_keyword(scope, keyword)
        scope.search_by_keyword(keyword)
      end
    end
  end
end
