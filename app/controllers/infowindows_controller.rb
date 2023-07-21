class InfowindowsController < ApplicationController
  skip_after_action :verify_authorized
  skip_before_action :authenticate_user!

  def new
    @frame_id = params[:frame_id]
    @location = Location.find @frame_id.delete("loc_")
  end
end
