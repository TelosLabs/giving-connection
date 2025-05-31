class SaveButton::Component < ApplicationViewComponent
  include ActionButtonHelper

  def initialize(user:, location:, simplified: false, tooltip_position: "")
    @user = user
    @location = location
    @simplified = simplified
    @tooltip_position = tooltip_position
    @removable_fav_location = removable_fav_location?
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

  def button_styles
    @simplified ? "relative" : action_button_styles[:button]
  end

  def wrapper_styles
    action_button_styles[:icon_wrapper] unless @simplified
  end

  def copy_styles
    @simplified ? "sr-only" : action_button_styles[:copy]
  end

  def icon_name
    removable_fav_location? ? "bookmark_colored.svg" : "bookmark_empty.svg"
  end

  def removable_fav_location?
    @user.present? && FavoriteLocation.exists?(user_id: @user&.id, location_id: @location.id)
  end

  def favorite_location
    FavoriteLocation.find_by(user_id: @user.id, location_id: @location.id)
  end

  def btn_selector
    selector = "save-location-#{@location.id}-btn"
    selector << "__simplified" if @simplified
    selector
  end
end
