Geocoder.configure(
  lookup: :google,
  api_key: Rails.application.credentials.dig(:ruby_llm, :gemini),
  http_headers: {"User-Agent" => "my_rails_app (jorge@teloslabs.co)"},
  timeout: 5,
  units: :km
)
