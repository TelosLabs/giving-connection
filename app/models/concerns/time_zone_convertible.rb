module TimeZoneConvertible
  extend ActiveSupport::Concern

  def open_time=(value)
    if value.present?
      converted_time = convert_time_to_utc(value)
      super(converted_time)
    else
      super
    end
  end

  def close_time=(value)
    if value.present?
      converted_time = convert_time_to_utc(value)
      super(converted_time)
    else
      super
    end
  end

  def in_local_time(time)
    return if time.blank?

    # Convert from UTC back to local timezone
    local_timezone = ActiveSupport::TimeZone[time_zone]
    time.in_time_zone(local_timezone)
  end

  private

  def convert_time_to_utc(time)
    return nil if time.blank?

    # If it's already a Time object in UTC, return it as is
    if time.is_a?(Time) && time.zone == "UTC"
      return time
    end

    # Get the time string (HH:MM:SS format)
    time_str = if time.is_a?(Time)
      time.strftime("%H:%M:%S")
    elsif time.is_a?(String)
      # Ensure we have seconds if not provided
      time.match?(/\d{2}:\d{2}:\d{2}/) ? time : "#{time}:00"
    else
      time.to_s
    end

    # Create a Time object in the local timezone using today's date
    local_timezone = ActiveSupport::TimeZone[time_zone]
    today = Date.current
    local_time = local_timezone.parse("#{today} #{time_str}")

    # Convert to UTC
    local_time.utc
  end
end
