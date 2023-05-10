# frozen_string_literal: true

class OfficeHoursValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record
    close_hour_after_open_hour
  end

  private

  def close_hour_after_open_hour
    return true if record.closed?
    return true if record.location.offer_services == false
    return true if record.location.appointment_only?

    if record&.open_time&.>= record&.close_time
      record.location.organization.errors.add(:base, 'Closing time must be after opening time')
    end
  end
end
