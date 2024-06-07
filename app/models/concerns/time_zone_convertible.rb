module TimeZoneConvertible
  extend ActiveSupport::Concern

  included do
    before_save :convert_times_to_utc
  end

  def convert_times_to_utc
    raise "Time zone must be present" if time_zone.blank?

    converter = TimeZoneConverter.new(time_zone)

    converted_open_time = converter.to_utc(open_time.strftime("%H:%M:%S"))
    converted_close_time = converter.to_utc(close_time.strftime("%H:%M:%S"))

    # Handle rollover
    if converted_close_time < converted_open_time
      # Adjust close time to next day
      converted_close_time += 1.day
    end

    self.open_time = converted_open_time
    self.close_time = converted_close_time
  end
end
