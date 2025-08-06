# frozen_string_literal: true

class SearchPills::Component < ApplicationViewComponent
  def initialize(causes:, services:, current_location:, beneficiary_subcategories:, params:)
    @causes = causes
    @services = services
    @current_location = current_location
    @beneficiary_subcategories = beneficiary_subcategories
    @params = params
    @tabs_labels = ["Causes", "Location", "Services", "Populations Served", "Hours"]
    @radii_in_miles = [2, 5, 15, 30, 60, 180, "Any"]
    @tooltips = {
      "Causes" => "The broad issue areas or missions that the nonprofit supports.",
      "Services" => "The specific programs or activities the nonprofit offers to the community."
    }
  end

  def miles_to_km(miles)
    (miles == "Any") ? 1_000_000 : (miles * 1.609344).round(3)
  end

  def tooltip_for(tab_label)
    @tooltips[tab_label]
  end

  def has_tooltip?(tab_label)
    @tooltips.key?(tab_label)
  end
end
