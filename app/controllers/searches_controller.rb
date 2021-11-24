# frozen_string_literal: true

class SearchesController < ApplicationController
  def new
    @search = Search.new
    authorize @search
  end

  def create
    @search = Search.new(create_params)
    if @search.search && @search.results.any?
      @results = @search.results
      redirect_to locations_path(ids: @results.ids)
    else
      puts 'didnt work'
    end
    authorize @search
  end

  def keyword_params
    params.permit(:keyword)
  end

  def create_params
    params.permit(:distance, :city, :state, :beneficiary_groups,
                  :services, :open_now, :open_weekends, :keyword)
  end
end
