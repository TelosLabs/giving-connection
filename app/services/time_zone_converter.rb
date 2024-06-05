class TimeZoneConverter < ApplicationService
  def initialize(time_zone, est_time_zone = "Eastern Time (US & Canada)")
    @time_zone = time_zone.is_a?(ActiveSupport::TimeZone) ? time_zone : ActiveSupport::TimeZone[time_zone]
    @est_time_zone = ActiveSupport::TimeZone[est_time_zone]
  end

  def from_time_zone_to_est(time_str)
    return nil if time_str.blank?

    local_time = @time_zone.parse(time_str)
    local_time.in_time_zone(@est_time_zone)
  end

  def from_est_to_time_zone(time_str)
    return nil if time_str.blank?

    est_time = @est_time_zone.parse(time_str)
    est_time.in_time_zone(@time_zone)
  end
end
