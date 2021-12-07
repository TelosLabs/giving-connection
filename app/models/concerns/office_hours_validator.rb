class OfficeHoursValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record
    close_hour_after_open_hour
  end

  private

  def close_hour_after_open_hour
    # return true if record.closed?

    # if record&.open_time >= record&.close_time
    #   record.location.organization.errors.add(:base, 'Closing time must be after opening time')
    # end
    true
  end

end
