class LocationInfowindow::Component < ApplicationViewComponent
  def initialize(location:, user_signed_in:, current_user:)
    @location = location
    @user_signed_in = user_signed_in
    @current_user = current_user
  end

  def default_bookmark_options
    {
      url: favorite_locations_path(location_id: @location.id),
      class: "inline-flex self-end text-xs text-gray-3"
    }
  end

  def custom_bookmark_options
    if !(@user_signed_in)
      {
        data: { turbo_method: :post }
      }
    elsif @current_user.favorited_locations.include?(@location)
      {
        remote: true,
        data: {
          action: "click->pin#reloadPage",
          turbo_method: :delete
        }
      }
    else 
      {
        remote: true,
        data: {
          action: "click->pin#reloadPage",
          turbo_method: :post
        }
      }
    end
  end

  def bookmark_options
    default_bookmark_options.merge(custom_bookmark_options)
  end

  def bookmark_icon
    if @user_signed_in && @current_user.favorited_locations.include?(@location)
      "bookmark_colored.svg"
    else
      "bookmark_empty.svg"
    end
  end
end
