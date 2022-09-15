module LocationsHelper
  def display_day_working_hours(office_hour)
    return "Closed" if office_hour.closed?
    "#{office_hour.open_time.strftime("%l %p")}-#{office_hour.close_time.strftime("%l %p")} (CST)"
  end

  def get_ip_location
    reader = MaxMind::DB.new("#{Rails.root}/app/assets/GeoLite2-City.mmdb", mode: MaxMind::DB::MODE_MEMORY)

    record = reader.get('24.165.90.33')
    if record.nil?
      puts request.remote_ip.to_s
      puts '1.1.1.1 was not found in the database'
    else
      puts record.to_hash
      return [
        {
          city: record.to_hash['city']['names']['en'],
          state: record.to_hash['subdivisions'][0]['iso_code'],
          latitude: record.to_hash['location']['latitude'],
          longitude: record.to_hash['location']['longitude'],
          type: 'ip'
        },
        {
          city: 'Current Location',
          state: '',
          latitude: '',
          longitude: '',
          type: 'current_location'
        }
      ]
    end

    reader.close
  end
end
