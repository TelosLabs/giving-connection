# frozen_string_literal: true

class SearchesController < ApplicationController
  def new
    @search = Search.new
  end

  def keyword_search
    search = Search.new(keyword_params)
    if search.keyword_search && search.results.any?
      @results = search.results
      redirect_to locations_path(ids: @results.ids)
    else
      puts 'didnt work'
    end
  end

  def filter_search
    search = Search.new(create_params)
    # raise
    if search.filter_search && search.results.any?
      @results = search.results
      redirect_to locations_path(ids: @results.ids)
    else
      puts 'didnt work'
    end
  end

  def keyword_params
    params.permit(:keyword)
  end

  def create_params
    params.permit(:distance, :city, :state, :beneficiary_groups, 
                  :cause_and_services, :open_now, :open_weekends)
  end
end
