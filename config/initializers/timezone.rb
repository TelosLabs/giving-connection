Timezone::Lookup.config(:geonames) do |c|
  c.username = Rails.application.credentials.dig(:geonames, :username) || ENV["GEONAMES_USERNAME"] || "development_user"
end
