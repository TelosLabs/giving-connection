class SearchPreviewsController < ApplicationController
  def show
    skip_authorization
    @tabs_labels = ['Causes', 'Location', 'Services', 'Populations Served', 'Hours']
    @radii_in_miles = [2, 5, 15, 30, 60, 180, "Any"]
  end
end
