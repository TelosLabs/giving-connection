class ListCalendarSwitchBtn::Component < ApplicationViewComponent
  include ActionButtonHelper

  def initialize(user:, location:, simplified: false)
    @user = user
    @location = location
    @simplified = simplified
  end

  def link_args
    if removable_fav_location?
      {
        path: favorite_location_path(favorite_location),
        method: :delete
      }
    else
      {
        path: favorite_locations_path(location_id: @location.id),
        method: :post
      }
    end
  end
end
