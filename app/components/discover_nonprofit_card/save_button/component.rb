class DiscoverNonprofitCard::SaveButton::Component < ViewComponent::Base
  def initialize(user:, location:, button_styles: "", icon_wrapper_styles: "", action_copy_styles: "")
    @user = user
    @location = location
    @link_args = get_link_args
    # to be consistent with the rest of buttons in the menu
    @button_styles = button_styles
    @icon_wrapper_styles = icon_wrapper_styles
    @action_copy_styles = action_copy_styles
  end

  def get_link_args
    # user logged out
    if @user.nil?
      {
        params: {
          location_id: @location
        },
        method: :post
      }
    # removing saved nonprofit
    elsif FavoriteLocation.exists?(user_id: @user&.id, location_id: @location.id)
      {
        params: {
          id: FavoriteLocation.find_by(user_id: @user.id, location_id: @location.id),
          origin: "location_show"
        },
        method: :delete
      }
    # saving nonprofit
    else
      {
        params: {
          location_id: @location,
          origin: "location_show"
        },
        method: :post
      }
    end
  end

  def saved
    # styles for saved icon
    FavoriteLocation.exists?(user_id: @user&.id, location_id: @location.id) ? "saved" : ""
  end

  def link_path
    @link_args[:method] == :delete ? favorite_location_path(@link_args[:params]) : favorite_locations_path(@link_args[:params])
  end
end
