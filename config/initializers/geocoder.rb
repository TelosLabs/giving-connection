Geocoder.configure(
  lookup: :google,
  api_key: Rails.application.credentials.dig(:google_geocoder_api_key),
  http_headers: {"User-Agent" => "my_rails_app (jorge@teloslabs.co)"},
  timeout: 5,
  units: :km
)
