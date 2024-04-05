# frozen_string_literal: true

class CausesController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @causes = policy_scope(Cause)
    authorize @causes
  end

  def show
    @cause = Cause.find_by(name: params[:name])
    authorize @cause
    @search = Search.new(
      city: @current_location[:city],
      state: @current_location[:state],
      lat: @current_location[:latitude],
      lon: @current_location[:longitude],
      causes: [@cause.name]
    )
    @locations_by_services = if @search.save
      Location.sort_by_more_services(@search.results)
    else
      filtered_locations = Location.locations_with_(@cause)
      Location.sort_by_more_services(filtered_locations)
    end
  end
end
