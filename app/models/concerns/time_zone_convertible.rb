module TimeZoneConvertible
  extend ActiveSupport::Concern

  included do
    before_save :convert_times_to_utc, if: :open_and_close_times_present?
  end

  def convert_times_to_utc
    return if time_zone.blank?

    # Convert open_time to UTC
    if open_time.present?
      local_open_time = parse_time_in_timezone(open_time, time_zone)
      self.open_time = local_open_time.utc
    end

    # Convert close_time to UTC
    if close_time.present?
      local_close_time = parse_time_in_timezone(close_time, time_zone)
      self.close_time = local_close_time.utc
    end
  end

  def in_local_time(utc_time)
    return nil if utc_time.blank? || time_zone.blank?

    # Since time columns only store time, not date, we need to create a full datetime
    # for proper timezone conversion using today's date
    today = Date.current.in_time_zone(time_zone)
    utc_datetime = Time.utc(today.year, today.month, today.day,
      utc_time.hour, utc_time.min, utc_time.sec)

    # Convert the UTC datetime to local timezone
    utc_datetime.in_time_zone(time_zone)
  end

  private

  def open_and_close_times_present?
    open_time.present? && close_time.present?
  end

  def parse_time_in_timezone(time_input, timezone)
    local_tz = timezone.is_a?(ActiveSupport::TimeZone) ? timezone : ActiveSupport::TimeZone[timezone]

    case time_input
    when Time
      # Extract just the time components and create a new time in the local timezone
      time_str = time_input.strftime("%H:%M:%S")
      today = Date.current.in_time_zone(local_tz)
      local_tz.parse("#{today.strftime("%Y-%m-%d")} #{time_str}")
    when String
      # Parse string as local time in the specified timezone
      # Use today's date to create a proper datetime
      today = Date.current.in_time_zone(local_tz)
      time_str = time_input.match?(/\d{2}:\d{2}:\d{2}/) ? time_input : "#{time_input}:00"
      local_tz.parse("#{today.strftime("%Y-%m-%d")} #{time_str}")
    else
      # Convert to string and parse
      parse_time_in_timezone(time_input.to_s, timezone)
    end
  end
end
