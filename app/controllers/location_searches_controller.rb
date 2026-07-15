# frozen_string_literal: true

# Server-side endpoints backing the search-bar location typeahead. Public
# (anonymous visitors use the home search bar), so auth is skipped like
# SearchesController.
#
#   GET /location_search/suggestions?q=nash  -> HTML <li> options (stimulus-autocomplete)
#   GET /location_search/geocode?q=Nashville -> JSON { latitude, longitude, city }
class LocationSearchesController < ApplicationController
  skip_before_action :authenticate_user!
  # These are background lookup fetches, not real page visits — don't let them
  # overwrite the stored post-login redirect location.
  skip_before_action :store_user_location!, raise: false
  # Lightweight lookup endpoints, not authorized resources.
  skip_after_action :verify_authorized

  def suggestions
    predictions = LocationAutocomplete.call(params[:q])
    render partial: "location_searches/suggestion", collection: predictions, as: :prediction, layout: false
  end

  def geocode
    location = LocationGeocoder.call(params[:q])

    if location
      render json: location
    else
      render json: { error: "not_found" }, status: :unprocessable_entity
    end
  end
end
