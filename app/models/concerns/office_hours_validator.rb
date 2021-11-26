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

    record.organization.errors.add(:base, 'Closing time must be after opening time') if record.open_time >= record.close_time
  end
end
