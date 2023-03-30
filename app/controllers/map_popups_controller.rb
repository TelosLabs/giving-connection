class MapPopupsController < ApplicationController
  # TODO: Authorize action
  skip_after_action :verify_authorized
  skip_before_action :authenticate_user!

  def new
    @org = Location.find(params[:location_id])
  end
end
