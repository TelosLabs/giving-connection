# frozen_string_literal: true

class SearchPills::Component < ApplicationViewComponent
  def initialize(causes:, services:, beneficiary_subcategories:, params:)
    @causes = causes
    @services = services
    @beneficiary_subcategories = beneficiary_subcategories
    @params = params
    @tabs_labels = ['Causes', 'Location', 'Services', 'Populations Served', 'Hours']
    @radii_in_miles = [2, 5, 15, 30, 60, 180, "Any"]
  end

  def miles_to_km(miles)
    miles == "Any" ? 1_000_000 : (miles * 1.609344).round(3)
  end
end
