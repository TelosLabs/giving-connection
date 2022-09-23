module Locationable
  extend ActiveSupport::Concern
  LOCAL_HOST_IP = '127.0.0.1'
  DEFAULT_LATITUDE = 29.7604
  DEFAULT_LONGITUDE = -95.3698
  DEFAULT_CITY = 'Houston'
  DEFAULT_STATE = 'TX'
  DEFAULT_COUNTRY = "EE. UU."

  included do
    before_action :set_location
  end

  def set_location
    @current_location = current_location
  end
  private

  def current_location
    #TODO: Add new methods to find current_location
    location_from_params || location_from_ip || location_from_session || default_location# || location_from_cookie
  end

  def location_from_params
    return nil if params&.dig("search", "lat").blank? || params&.dig("search", "lon").blank?
    {
      city: params&.dig("search", "city"),
      state: params&.dig("search", "state"),
      country: params&.dig("search", "country"),
      latitude: params&.dig("search", "lat"),
      longitude: params&.dig("search", "lon")
    }
  end

  def location_from_ip
    GeoLocationSearch.new.search(ip_address: request.ip)
  end

  def location_from_session
    {
      city: session.dig("current_location", "city"),
      state: session.dig("current_location", "state"),
      country: session.dig("current_location", "country"),
      latitude: session.dig("current_location", "latitude"),
      longitude: session.dig("current_location", "longitude")
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