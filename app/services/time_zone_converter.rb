class TimeZoneConverter < ApplicationService
  def initialize(local_time_zone, utc_time_zone = "UTC")
    @local_time_zone = local_time_zone.is_a?(ActiveSupport::TimeZone) ? local_time_zone : ActiveSupport::TimeZone[local_time_zone]
    @utc_time_zone = ActiveSupport::TimeZone[utc_time_zone]
  end

  def to_utc(time_str)
    raise ArgumentError, "Invalid time string" unless time_str.is_a?(String) && time_str.match?(/\d{2}:\d{2}:\d{2}/)
    return nil if time_str.blank?

    local_time = @local_time_zone.parse(time_str)
    local_time.in_time_zone(@utc_time_zone)
  end

  def to_local(time_str)
    return nil if time_str.blank?

    utc_time = @utc_time_zone.parse(time_str)
    utc_time.in_time_zone(@local_time_zone)
  end
end
