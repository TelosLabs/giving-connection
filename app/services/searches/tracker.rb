# frozen_string_literal: true

module Searches
  # Records a keyword search in the search_terms table.
  #
  # Two things it deliberately does NOT record:
  #
  # 1. Refinements. Every filter pill, distance button and city change re-submits
  #    the search form with the keyword unchanged, so counting raw requests would
  #    inflate one search into five. `previous_keyword` is the last term recorded
  #    in this session; an unchanged keyword is a refinement, not a new search.
  # 2. Anything identifying. No user, IP or session id is written — see the
  #    migration for why.
  #
  # Analytics must never break search, so a failure here is logged and swallowed.
  class Tracker < ApplicationService
    ORIGINS = %w[home search_results search_landing nonprofit_profile].freeze

    def initialize(keyword:, results_count:, origin: nil, city: nil, state: nil,
      filtered: false, previous_keyword: nil)
      @keyword = keyword
      @results_count = results_count
      @origin = origin
      @city = city
      @state = state
      @filtered = filtered
      @previous_keyword = previous_keyword
    end

    def call
      return if normalized_keyword.blank?
      return if normalized_keyword == SearchTerm.normalize(@previous_keyword)

      SearchTerm.create!(
        keyword: @keyword.to_s.strip.first(SearchTerm::MAX_KEYWORD_LENGTH),
        normalized_keyword: normalized_keyword,
        results_count: @results_count.to_i,
        origin: ORIGINS.include?(@origin) ? @origin : nil,
        city: @city.presence,
        state: @state.presence,
        filtered: ActiveModel::Type::Boolean.new.cast(@filtered) || false
      )
    rescue => e
      Rails.logger.warn("Searches::Tracker failed to record a search term: #{e.class}: #{e.message}")
      nil
    end

    private

    def normalized_keyword
      @normalized_keyword ||= SearchTerm.normalize(@keyword)
    end
  end
end
