class MapPopupsController < ApplicationController
  # TODO: Authorize action
  skip_after_action :verify_authorized

  def new
    @org = Location.find(params[:location_id])
  end
end
