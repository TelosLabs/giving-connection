# frozen_string_literal: true

class FavoriteLocationsController < ApplicationController
  def create
    @location = Location.find(params['location'])
    new_favorite_location = FavoriteLocation.new(location: @location, user: current_user)
    redirect_to locations_path if new_favorite_location.save
  end

  def destroy
    @favorite_location = FavoriteLocation.find(params[:id])
    @favorite_location.destroy
    redirect_to locations_path
  end
end
