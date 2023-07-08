class LocationInfowindow::Component < ApplicationViewComponent
  def initialize(location:, user_signed_in:, current_user:)
    @location = location
    @user_signed_in = user_signed_in
    @current_user = current_user
  end
end
