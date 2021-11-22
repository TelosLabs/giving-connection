class OfficeHoursValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record
    close_hour_after_open_hour
  end

  private

  def close_hour_after_open_hour
    if record.open_time >= record.close_time
      record.errors.add(:base, 'Closing time must be after openinig time')
    end
  end

end
