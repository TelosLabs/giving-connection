# frozen_string_literal: true

class SearchesController < ApplicationController
  def new
    @search = Search.new
  end

  def create
    search = Search.new(create_params)
    if search.save && search.results.any?
      @results = search.results
      redirect_to locations_path(ids: @results.ids)
    else
      puts 'didnt work'
    end
  end

  def create_params
    params.require(:search).permit(:keyword, :kilometers)
  end
end
