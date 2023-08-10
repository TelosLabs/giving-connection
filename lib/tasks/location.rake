namespace :location do
  desc 'map appointment_only values into non_standard_office_hours column'
  task appointment_only_to_non_standard_office_hours: :environment do
    Location.all.each do |location|
      location.update non_standard_office_hours: location.appointment_only ? 1 : nil
    end
  end
end
