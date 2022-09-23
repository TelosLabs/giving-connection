class GeoLocationSearch < ApplicationService

  def search(ip_address:)
    return nil if ip_address.blank?
    response = $max_mind_db.lookup(ip_address)
    get_location(response)
  end

  def get_location(response)
    return nil if response.nil? || response.found? == false

    {
      city: response.city.name(:en),
      state: response.subdivisions.most_specific.name(:en),
      country: response.country.name(:en),
      latitude: response.location.latitude,
      longitude: response.location.longitude
    }
  end
end