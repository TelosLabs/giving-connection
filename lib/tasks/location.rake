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
      timezone = ActiveSupport::TimeZone::MAPPING.key(geoname_timezone) || "Eastern Time (US & Canada)"

      if location.update time_zone: timezone
        updated_locations += 1
      else
        not_updated_locations << location.id
      end
    end

    Rails.logger.info "Updated locations total: #{updated_locations}"
    Rails.logger.info "List of locations that couldn't be updated: #{not_updated_locations}" if not_updated_locations.present?
    Rails.logger.info "Not updated locations total: #{not_updated_locations.size}" if not_updated_locations.present?
  end

  desc "change times to UTC"
  task convert_times_to_utc: :environment do
    not_updated_office_hours = []
    updated_office_hours = 0

    Location.with_office_hours.find_each do |location|
      location.office_hours.each do |office_hour|
        if office_hour.open_time.present? && office_hour.close_time.present?
          office_hour.convert_times_to_utc
          if office_hour.save
            updated_office_hours += 1
          else
            not_updated_office_hours << office_hour.id
          end
        end
      end
    end

    Rails.logger.info "Updated locations total: #{updated_office_hours}"
    Rails.logger.info "List of locations that couldn't be updated: #{not_updated_office_hours}" if not_updated_office_hours.present?
    Rails.logger.info "Not updated locations total: #{not_updated_office_hours.size}" if not_updated_office_hours.present?
  end
end
