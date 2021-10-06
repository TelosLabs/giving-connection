class LocationsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    @location = Location.new()
  end

  def create
    location = Location.new(create_params)
    if location.save
      redirect_to root_path
    else
      puts "Loc creation failed: #{location.errors.full_messages.to_sentence}"
    end
  end

  private

  def create_params
    params.require(:location).permit(:address, :longitude, :latitude)
  end
end
