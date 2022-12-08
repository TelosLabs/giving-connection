class DiscoverNonprofitCard::ActionsMenu::SaveButton::Component < ViewComponent::Base
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
    if @user.nil?
      {
        params: {
          location_id: @location
        },
        method: :post,
        data: {}
      }
    # removing saved nonprofit
    elsif FavoriteLocation.exists?(user_id: @user&.id, location_id: @location.id)
      {
        params: {
          id: FavoriteLocation.find_by(user_id: @user.id, location_id: @location.id),
        },
        method: :delete,
        data: { controller: "bookmark-subscription", action: "click->bookmark-subscription#reloadPage" }
      }
    # saving nonprofit
    else
      {
        params: {
          location_id: @location,
        },
        method: :post,
        data: { controller: "bookmark-subscription", action: "click->bookmark-subscription#reloadPage" }
      }
    end
  end

  def saved
    FavoriteLocation.exists?(user_id: @user&.id, location_id: @location.id) ? "saved" : ""
  end

  def link_path
    @link_args[:method] == :delete ? favorite_location_path(@link_args[:params]) : favorite_locations_path(@link_args[:params])
  end
end
