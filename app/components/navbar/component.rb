class Navbar::Component < ApplicationViewComponent
  def initialize(signed_in:, current_location:, locations: @locations)
    @current_location = current_location
    @signed_in = signed_in
    @locations = locations
  end

  def non_sticky_paths
    request.env["PATH_INFO"] == "/searches" || request.env["PATH_INFO"] == "/my_account"
  end
end
