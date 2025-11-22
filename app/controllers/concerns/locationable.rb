module Locationable
  extend ActiveSupport::Concern

  LOCAL_HOST_IP = "127.0.0.1"
  DEFAULT_LATITUDE = 36.16404968727089
  DEFAULT_LONGITUDE = -86.78125827725053
  DEFAULT_STATE = "Tennessee"
  DEFAULT_COUNTRY = "USA"
  AVAILABLE_CITIES = ["Nashville", "Atlantic City", "Los Angeles", "Search all"].freeze
  DEFAULT_CITY = self::AVAILABLE_CITIES.first

  included do
    before_action :set_location
  end

  def set_location
    @current_location = current_location
    @locations = self.class::AVAILABLE_CITIES
  end

  private

  def current_location
    location_from_params ||
      location_from_cookie ||
      default_location
    # TODO
    # || location_from_ip || location_from_session
  end

  def location_from_params
    return nil if params&.dig("search", "lat").blank? || params&.dig("search", "lon").blank? || params&.dig("search", "city").blank?
    {
      city: params&.dig("search", "city"),
      state: params&.dig("search", "state"),
      country: params&.dig("search", "country"),
      latitude: params&.dig("search", "lat"),
      longitude: params&.dig("search", "lon")
    }
  end

  def location_from_cookie
    return nil if cookies[:city].blank?
    {
      city: cookies[:city],
      state: cookies[:state],
      country: cookies[:country],
      latitude: cookies[:latitude],
      longitude: cookies[:longitude]
    }
  end

  def default_location
    {
      city: DEFAULT_CITY,
      state: DEFAULT_STATE,
      country: DEFAULT_COUNTRY,
      latitude: DEFAULT_LATITUDE,
      longitude: DEFAULT_LONGITUDE
    }
  end
end
