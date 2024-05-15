namespace :location do
  desc "map appointment_only values into non_standard_office_hours column"
  task appointment_only_to_non_standard_office_hours: :environment do
    not_updated_locations = []
    updated_locations = 0

    Location.all.find_each do |location|
      if location.update non_standard_office_hours: location.appointment_only ? 1 : nil
        updated_locations += 1
      else
        not_updated_locations << location.id
      end
    end

    Rails.logger.info "Updated locations total: #{updated_locations}"
    Rails.logger.info "List of locations that couldn't be updated: #{not_updated_locations}" if not_updated_locations.present?
    Rails.logger.info "Not updated locations total: #{not_updated_locations.size}" if not_updated_locations.present?
  end

  desc "set time_zone for locations that offer services and have a pin on the map"
  task set_time_zone: :environment do
    not_updated_locations = []
    updated_locations = 0

    Location.all.find_each do |location|
      geoname_timezone = Timezone.lookup(location.latitude, location.longitude)
      timezone = ActiveSupport::TimeZone::MAPPING.key(geoname_timezone)

      if location.update time_zone: timezone.name
        updated_locations += 1
      else
        not_updated_locations << location.id
      end
    end

    Rails.logger.info "Updated locations total: #{updated_locations}"
    Rails.logger.info "List of locations that couldn't be updated: #{not_updated_locations}" if not_updated_locations.present?
    Rails.logger.info "Not updated locations total: #{not_updated_locations.size}" if not_updated_locations.present?
  end
end
