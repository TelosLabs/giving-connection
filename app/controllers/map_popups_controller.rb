class MapPopupsController < ApplicationController
  skip_after_action :verify_authorized
  skip_before_action :authenticate_user!

  def new
    @location = Location.find(params[:location_id])
  end
end
