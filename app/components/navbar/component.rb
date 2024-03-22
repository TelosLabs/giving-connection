class Navbar::Component < ApplicationViewComponent
  def initialize(signed_in:, current_location:)
    @current_location = current_location
    @locations = Search::AVAILABLE_CITIES
    @signed_in = signed_in
  end

  def non_sticky_paths
    request.env["PATH_INFO"] == "/searches" || request.env["PATH_INFO"] == "/my_account"
  end
end
