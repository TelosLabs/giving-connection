Timezone::Lookup.config(:geonames) do |c|
  c.username = Rails.application.credentials.geonames[:username]
end
