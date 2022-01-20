# frozen_string_literal: true

class LocationsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @location = Location.find(params[:id])
    authorize @location
  end

  def new
    @location = Location.new
    authorize @location
  end

  def delete
    @location = Location.find(params[:id])
    @ocation.destroy
  end

  private

  def create_params
    params.require(:location).permit(:address, :longitude, :latitude)
  end
end
