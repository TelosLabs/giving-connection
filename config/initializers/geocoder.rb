Geocoder.configure(
  lookup: :nominatim,
  http_headers: { "User-Agent" => "my_rails_app (jorge@teloslabs.co)" },
  timeout: 5,
  units: :km
)
