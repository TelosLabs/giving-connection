# frozen_string_literal: true

class SearchesController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    @saerch = Search.new
  end

  def create
    search = Search.new(create_params)

    if search.save && search.results.any?
      @results = search.results
      redirect_to locations_path(ids: @results.ids, alert_params: create_params)
    else
      render :new
      puts search.errors.full_messages
    end
  end

  def create_params
    params.permit(:distance, :city, :state, :beneficiary_groups,
                  :services, :open_now, :open_weekends, :keyword,
                  :search_type)
  end
end
